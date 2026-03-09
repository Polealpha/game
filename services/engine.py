from __future__ import annotations

import copy
import json
import math
import os
import random
import sys
import threading
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

from .ark_client import ArkClient

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
HOUSE_DEFS: dict[str, dict[str, str]] = {
    "贫民街": {
        "id": "slum_house",
        "title": "山坡租屋",
        "class": "low",
        "district": "贫民街",
        "scene_id": "forest_farm",
        "entry_spawn_id": "farm_gate",
        "anchor_x": "610.0",
        "anchor_y": "560.0",
    },
    "港口": {
        "id": "dock_house",
        "title": "石桥住屋",
        "class": "dock",
        "district": "港口",
        "scene_id": "stonebridge_quarter",
        "entry_spawn_id": "bridge_square",
        "anchor_x": "860.0",
        "anchor_y": "720.0",
    },
    "工厂区": {
        "id": "factory_house",
        "title": "厂房宿舍",
        "class": "industrial",
        "district": "工厂区",
        "scene_id": "watermill_yard",
        "entry_spawn_id": "mill_gate",
        "anchor_x": "2240.0",
        "anchor_y": "1120.0",
    },
    "交易所": {
        "id": "exchange_house",
        "title": "账房公寓",
        "class": "merchant",
        "district": "交易所",
        "scene_id": "rune_tower",
        "entry_spawn_id": "tower_steps",
        "anchor_x": "1370.0",
        "anchor_y": "610.0",
    },
}

SUBREGION_ROUTE_POINTS: dict[str, list[tuple[float, float]]] = {
    "forest_farm": [(430.0, 320.0), (560.0, 300.0), (700.0, 360.0), (610.0, 540.0)],
    "courtyard_garden": [(410.0, 700.0), (560.0, 760.0), (700.0, 860.0), (520.0, 930.0)],
    "wild_path": [(250.0, 1470.0), (420.0, 1510.0), (600.0, 1430.0), (740.0, 1570.0)],
    "shipyard_workshop": [(980.0, 1510.0), (1190.0, 1610.0), (1450.0, 1530.0), (1600.0, 1660.0)],
    "canal_harbor": [(1080.0, 980.0), (1260.0, 1080.0), (1440.0, 980.0), (1490.0, 1180.0)],
    "stonebridge_quarter": [(700.0, 720.0), (860.0, 720.0), (990.0, 820.0), (820.0, 920.0)],
    "watermill_yard": [(1920.0, 980.0), (2140.0, 1110.0), (2310.0, 1220.0), (2050.0, 1320.0)],
    "stoneyard_workcamp": [(2350.0, 1400.0), (2520.0, 1460.0), (2690.0, 1530.0), (2440.0, 1600.0)],
    "clocktower_market": [(2050.0, 220.0), (2240.0, 300.0), (2440.0, 330.0), (2640.0, 260.0)],
    "rune_tower": [(1220.0, 400.0), (1370.0, 610.0), (1530.0, 520.0), (1480.0, 310.0)],
    "church_graveyard": [(1950.0, 540.0), (2100.0, 500.0), (2240.0, 610.0), (2380.0, 660.0)],
}

HOUSE_PATROL_POINTS: dict[str, list[tuple[float, float]]] = {
    "slum_house": [(592.0, 582.0), (630.0, 584.0), (574.0, 620.0), (648.0, 618.0)],
    "dock_house": [(840.0, 736.0), (884.0, 738.0), (824.0, 774.0), (902.0, 772.0)],
    "factory_house": [(2214.0, 1140.0), (2258.0, 1142.0), (2202.0, 1178.0), (2270.0, 1176.0)],
    "exchange_house": [(1348.0, 628.0), (1394.0, 628.0), (1338.0, 666.0), (1402.0, 664.0)],
}


@dataclass
class ActionResult:
    message: str
    world_state: dict[str, Any]


class WorldEngine:
    def __init__(self, pulse_interval_seconds: int = 60) -> None:
        self.pulse_interval_seconds = pulse_interval_seconds
        self.random = random.Random(11)
        self.lock = threading.RLock()
        self.ark = ArkClient()
        self.goods_defs = self._load_json("goods.json")
        self.stock_defs = self._load_json("stocks.json")
        self.event_defs = self._load_json("events.json")
        self.npc_defs = self._load_json("npcs.json")
        self.family_defs = self._load_json("families.json")
        self.company_defs = self._load_json("companies.json")
        self.macro_defaults = self._load_json("macro.json")
        self.districts_defs = self._load_json("districts.json")
        self.dialogue_templates = self._load_json("dialogue_templates.json")
        self.demo_flow = self._load_json("demo_flow.json")
        self.task_defs = self._load_json("tasks.json")
        self.state: dict[str, Any] = {}
        self.reset()

    def reset(self) -> None:
        with self.lock:
            goods = []
            for good in self.goods_defs:
                item = copy.deepcopy(good)
                item["current_price"] = item["base_price"]
                item["price_trend"] = "平"
                goods.append(item)

            stocks = []
            for stock in self.stock_defs:
                item = copy.deepcopy(stock)
                item["current_price"] = item["base_price"]
                item["market_sentiment"] = "平"
                stocks.append(item)

            families = copy.deepcopy(self.family_defs)
            companies = copy.deepcopy(self.company_defs)
            for family in families:
                family["sector_focus"] = family.get("sector_focus", family["type"])
                family["hidden_action"] = family.get("hidden_action", "暂未出手")
            for family in families:
                self._bootstrap_family(family)
            for company in companies:
                self._bootstrap_company(company)
            districts = copy.deepcopy(self.districts_defs)
            subregions = self._flatten_subregions(districts)
            subregion_lookup = {row["id"]: row for row in subregions}
            npcs = copy.deepcopy(self.npc_defs)
            for index, npc in enumerate(npcs):
                npc["current_goal"] = npc.get("current_goal", "守住今天")
                npc["mood"] = npc.get("mood", "wary")
                npc["stance"] = npc.get("stance", "观望")
                npc["action_tendency"] = npc.get("action_tendency", "低头做事")
                npc["target"] = npc.get("target", npc["district"])
                npc["broadcast_intent"] = "low"
                npc["emotion_delta"] = {"fear": 0, "greed": 0}
                npc["speech_lines"] = []
                npc["cadence_seconds"] = 4.0
                npc["cooldown_until"] = 0.0
                npc["subregion_id"] = str(npc.get("subregion_id", ""))
                subregion_meta = subregion_lookup.get(npc["subregion_id"], {})
                npc["subregion_name"] = str(
                    npc.get("subregion_name", subregion_meta.get("name", ""))
                )
                npc["work_x"] = float(npc.get("x", 0.0))
                npc["work_y"] = float(npc.get("y", 0.0))
                house_meta = self._house_for_district(str(npc.get("district", "")))
                npc["home_id"] = house_meta["id"]
                npc["home_label"] = house_meta["title"]
                npc["home_class"] = house_meta["class"]
                home_x, home_y = self._derive_home_anchor(npc, index)
                npc["home_x"] = home_x
                npc["home_y"] = home_y
                npc["activity"] = "working"
                npc["home_state"] = "away"
                npc["indoor_activity"] = "away"
                npc["lights_on"] = False
                npc["schedule_note"] = "白天还在外面奔忙。"
                npc["schedule_role"] = self._schedule_role_for_npc(npc)

            for npc in npcs:
                self._bootstrap_npc(npc, companies)

            self.state = {
                "day": 1,
                "clock_minutes": 8 * 60,
                "time_period": "morning",
                "light_level": 0.95,
                "weather": {"kind": "sunny", "label": "晴天", "intensity": 0.12, "slot": -1, "day": 1},
                "last_tick_at": time.time(),
                "player": {
                    "cash": 30,
                    "credit": 20,
                    "reputation": 5,
                    "class_position": "底层",
                    "goods_inventory": {"面包": 1, "煤": 0, "罐头": 0},
                    "stock_holdings": {"蓝潮航运": 0, "黑石矿业": 0, "晨报传媒": 0},
                    "rumors": [],
                    "family_relations": {"白鹭家族": 0, "灰狼家族": 0, "猫头鹰家族": 0, "街头互助会": 0},
                    "task_progress": {},
                    "active_task_id": "",
                    "completed_tasks": [],
                },
                "goods": goods,
                "stocks": stocks,
                "families": families,
                "companies": companies,
                "districts": districts,
                "subregions": subregions,
                "current_subregion": "",
                "macro": copy.deepcopy(self.macro_defaults),
                "npcs": npcs,
                "ambient_speeches": {},
                "local_broadcasts": [],
                "rumor_log": [],
                "local_rumor": [],
                "district_topic": {},
                "city_news": [],
                "company_states": [],
                "family_moves": [],
                "institution_actions": [],
                "npc_truth_profile": {},
                "market_pressure": {
                    "goods": {row["name"]: 0.0 for row in goods},
                    "stocks": {row["name"]: 0.0 for row in stocks},
                    "families": {row["name"]: 0.0 for row in families},
                },
                "district_signals": {
                    district["name"]: {
                        "trade_heat": 0.0,
                        "labor_heat": 0.0,
                        "gossip": 0.0,
                        "fear": 0.0,
                        "liquidity": 0.0,
                    }
                    for district in districts
                },
                "global_news": [],
                "headline_news": [],
                "pending_events": [],
                "npc_highlights": [],
                "npc_cards": [],
                "house_states": {},
                "macro_summary": {},
                "quick_hud": {},
                "talk_topics": [],
                "demo_metrics": {
                    "work_actions": 0,
                    "goods_trades": 0,
                    "stock_trades": 0,
                    "intel_actions": 0,
                    "npc_talks": 0,
                    "days_ended": 0,
                    "ai_pulses": 0,
                },
                "task_board": copy.deepcopy(self.task_defs),
                "last_dialogue": {},
                "scene_observation": {},
                "scene_director_note": "",
                "llm_pulse_summary": "",
                "llm_market_note": "",
                "llm_scene_focus": "",
                "npc_spin_map": {},
                "family_briefings": {},
                "company_briefings": {},
                "npc_brief_history": {},
                "family_brief_history": {},
                "company_brief_history": {},
                "pulse_journal": [],
                "last_scene_capture_at": "未收到",
                "last_pulse_at": "未触发",
                "last_day_end_at": "未触发",
            }
            self._seed_global_news()
            self._apply_clock_state()
            self._apply_npc_schedule()
            self._generate_ai_pulse(trigger="boot")

    def snapshot(self) -> dict[str, Any]:
        with self.lock:
            self._advance_realtime_clock()
            self._refresh_derived_views()
            return copy.deepcopy(self.state)

    def action(self, action_type: str, district: str, payload: dict[str, Any] | None = None) -> ActionResult:
        payload = payload or {}
        with self.lock:
            self._advance_realtime_clock()
            self._advance_clock(16)
            match action_type:
                case "work":
                    return self._do_work(district)
                case "gather_info":
                    return self._gather_info(district)
                case "rest":
                    return self._rest_at_home(district, payload)
                case "cook_meal":
                    return self._cook_meal(district, payload)
                case "search_home":
                    return self._search_home(district, payload)
                case "review_ledger":
                    return self._review_ledger(district, payload)
                case "buy_goods":
                    return self._trade_good(payload["good_name"], int(payload.get("quantity", 1)), 1, payload)
                case "sell_goods":
                    return self._trade_good(payload["good_name"], int(payload.get("quantity", 1)), -1, payload)
                case "buy_stock":
                    return self._trade_stock(payload["stock_name"], int(payload.get("quantity", 1)), 1)
                case "sell_stock":
                    return self._trade_stock(payload["stock_name"], int(payload.get("quantity", 1)), -1)
                case "accept_task":
                    return self._accept_task(payload["task_id"])
                case "claim_task":
                    return self._claim_task(payload["task_id"])
                case _:
                    return ActionResult("未识别的行动。", self.snapshot())

    def end_day(self) -> ActionResult:
        with self.lock:
            self._advance_realtime_clock()
            self._run_livelihood_tick("end_day")
            self._settle_company_operations("end_day")
            self.state["day"] += 1
            self.state["clock_minutes"] = 6 * 60 + self.random.randint(0, 45)
            self._apply_clock_state()
            self._decay_district_signals()
            event = self._pick_event_for_day()
            self.state["pending_events"] = [event]
            self._apply_macro_shift(event)
            self._apply_goods_shift(event)
            self._apply_stock_shift(event)
            self._apply_family_shift(event)
            self._apply_district_shift(event)
            self._apply_institution_actions("end_day")
            self._append_news_for_event(event)
            self.state["last_day_end_at"] = self._now_label()
            self.state["demo_metrics"]["days_ended"] = int(self.state["demo_metrics"].get("days_ended", 0)) + 1
            self._generate_ai_pulse(trigger="end_day")
            self._apply_npc_schedule()
            self._refresh_derived_views()
            return ActionResult("黄铜钟响过，城市进入下一天。", self.snapshot())

    def ai_pulse(self, trigger: str = "scheduled", scene_observation: dict[str, Any] | None = None) -> ActionResult:
        with self.lock:
            self._advance_realtime_clock()
            self._advance_clock(28)
            self._run_livelihood_tick(trigger)
            self._settle_company_operations(trigger)
            self._apply_institution_actions(trigger)
            if scene_observation:
                self._record_scene_observation(scene_observation)
            self.state["demo_metrics"]["ai_pulses"] = int(self.state["demo_metrics"].get("ai_pulses", 0)) + 1
            self._generate_ai_pulse(trigger=trigger)
            var_allow_social_llm = not (trigger == "scheduled" and self._use_lightweight_scheduled_llm())
            self._run_agent_social_turns(scene_observation or {}, allow_llm=var_allow_social_llm)
            self._apply_intraday_market_move(reason="ai_pulse", decay=0.72)
            self._decay_district_signals()
            self._refresh_derived_views()
            return ActionResult("街头耳语刷新了。", self.snapshot())

    def reset_world(self) -> ActionResult:
        self.reset()
        return ActionResult("世界已重置回第一天清晨。", self.snapshot())

    def probe_ai(self) -> ActionResult:
        probe_result = self.ark.probe()
        message = probe_result["message"]
        snapshot = self.snapshot()
        snapshot["probe"] = probe_result
        return ActionResult(message, snapshot)

    def player_talk(
        self,
        npc_id: str,
        district: str,
        topic_id: str = "",
        approach: str = "cautious",
        intent: str = "",
        player_input: str = "",
        scene_observation: dict[str, Any] | None = None,
    ) -> ActionResult:
        with self.lock:
            npc = self._find_npc(npc_id)
            if not npc:
                return ActionResult("你身边没有这个角色。", self.snapshot())
            if scene_observation:
                self._record_scene_observation(scene_observation)

            player = self.state["player"]
            live_observation = copy.deepcopy(self.state.get("scene_observation", {}))
            self._refresh_derived_views()
            topic = self._resolve_talk_topic(npc, topic_id, district or npc["district"])
            truth_profile = self._truth_metrics_for_topic(npc, topic, approach, intent)
            trust_delta, intel_strength, npc_openness = self._evaluate_talk_approach(npc, topic, approach)
            self._queue_agent_task(npc, "player_talk", str(topic.get("label", "玩家搭话")))
            dialogue = None
            if self._consume_agent_budget(npc, "player_talk", 1):
                dialogue = self.ark.generate_dialogue_turn(
                    {
                        "speaker": {
                            "name": "壳仔",
                            "district": district or npc["district"],
                            "family_affiliation": "无",
                            "mood": "wary",
                            "current_goal": topic.get("label", "打听风声"),
                            "fear": 24,
                            "greed": 28,
                            "relationship_memory": copy.deepcopy(npc.get("player_memory", {})),
                        },
                        "speaker_agent": {
                            "agent_id": "player_proxy",
                            "system_prompt": "你是底层起步的乌龟玩家代理，问题短、谨慎、想知道价格和风向。",
                            "tool_policy": ["只能问问题", "不能替 NPC 决定", "必须说中文"],
                            "memory": copy.deepcopy(list(npc.get("relationship_memory", []))[:4]),
                        },
                        "listener": npc,
                        "listener_agent": self._npc_agent_profile(npc),
                        "district": district or npc["district"],
                        "trigger": "玩家搭话",
                        "topic": topic,
                        "approach": approach,
                        "intent": intent,
                        "player_input": player_input,
                        "scene_observation": live_observation,
                        "truth_profile": truth_profile,
                        "relationship_memory": {
                            "player_memory": copy.deepcopy(npc.get("player_memory", {})),
                            "recent_events": copy.deepcopy(list(npc.get("relationship_memory", []))[:4]),
                        },
                    }
                )
            player_input = player_input.strip()
            lines = [str(line) for line in dialogue.get("lines", [])[:2]] if dialogue else []
            stance = str(dialogue.get("stance", truth_profile.get("bias", npc.get("stance", "观望")))) if dialogue else str(
                truth_profile.get("bias", npc.get("stance", "观望"))
            )
            revealed_topic_ids = [str(value) for value in dialogue.get("revealed_topic_ids", []) if str(value).strip()] if dialogue else []
            if len(lines) < 2:
                lines = self._rule_player_talk_lines(npc, topic, approach, npc_openness, intent)
            if player_input:
                if not lines:
                    lines = [player_input, ""]
                else:
                    lines[0] = player_input
            if len(lines) < 2:
                fallback_lines = self._rule_player_talk_lines(npc, topic, approach, npc_openness, intent)
                lines = [player_input, fallback_lines[1]] if player_input else fallback_lines
            lines[1] = self._normalize_spoken_line(str(npc.get("name", "")), lines[1], self._rule_player_talk_lines(npc, topic, approach, npc_openness, intent)[1])
            if dialogue:
                self._remember_agent_output(npc, "player_talk", lines[1])

            npc["speech_lines"] = [lines[1], *npc["speech_lines"][:2]]
            npc["stance"] = stance
            npc["player_relation"] = int(npc.get("player_relation", 0)) + trust_delta
            npc["player_trust"] = max(0.0, min(100.0, float(npc.get("player_trust", 0.0)) + trust_delta * 2.4))
            player["credit"] = min(100, int(player["credit"]) + 1)
            player["reputation"] = min(100, int(player["reputation"]) + (1 if npc["class"] != "底层" and trust_delta > 0 else 0))
            npc["memory_tags"] = self._push_memory(npc["memory_tags"], "talk:player")
            npc["heard_topic_ids"] = self._push_memory(npc.get("heard_topic_ids", []), str(topic.get("id", "")))
            self.state["demo_metrics"]["npc_talks"] = int(self.state["demo_metrics"].get("npc_talks", 0)) + 1
            intel = self._build_intel_packet_from_topic(topic, npc, district or npc["district"])
            effective_strength = max(0.0, intel_strength * (0.45 + float(truth_profile.get("truthfulness", 0.5)) * 0.8))
            intel = self._spin_intel_packet(intel, npc, truth_profile, topic)
            promote_news = effective_strength >= 0.66 or str(topic.get("kind", "")) in {"asset", "family", "company", "institution", "panic"}
            if effective_strength > 0.12:
                self._apply_intel_packet(intel, to_player=True, promote_news=promote_news, intensity=effective_strength)
            self._remember_player_talk(npc, topic, approach, intent, trust_delta, effective_strength)
            self._bump_district_signal(npc["district"], "gossip", 0.12)
            self._bump_district_signal(npc["district"], "liquidity", 0.05 if topic.get("kind") in {"asset", "family", "company"} else 0.0)
            self.state["local_broadcasts"].insert(
                0,
                {
                    "source": "player",
                    "district": npc["district"],
                    "radius": 110,
                    "line": lines[1],
                    "type": "conversation",
                },
            )
            self.state["local_broadcasts"] = self.state["local_broadcasts"][:18]
            heard_by = self._apply_player_talk_fallout(npc, topic, intel, effective_strength, live_observation, lines[1], approach, intent)
            if not revealed_topic_ids:
                revealed_topic_ids = [str(topic.get("id", ""))]
            world_effects = self._describe_world_effects(intel, effective_strength)
            trade_quotes = self._default_trade_quotes_for_npc(npc)
            intel_note = intel["line"] if effective_strength > 0.12 else "这次没问出实货，只摸到一点态度。"
            self.state["last_dialogue"] = {
                "title": f"你与 {npc['name']} 交谈",
                "body": f"[b]话题[/b]：{topic.get('label', '街头风向')}  ·  [b]方式[/b]：{self._approach_label(approach)}\n\n[b]你[/b]：{lines[0]}\n\n[b]{npc['name']}[/b]：{lines[1]}\n\n[color=#6b4f2a][b]顺手递来的风声[/b][/color]\n{intel['line'] if intel_strength > 0 else '这次没问出实货，只摸到一点态度。'}\n\n[i]{npc['district']} 的风向因此更清楚了一点。[/i]",
                "tone": "conversation",
            }
            self.state["last_dialogue"]["body"] = (
                f"[b]话题[/b]：{topic.get('label', '街头风向')}  ·  [b]方式[/b]：{self._approach_label(approach)}\n\n"
                f"[b]你[/b]：{lines[0]}\n\n"
                f"[b]{npc['name']}[/b]：{lines[1]}\n\n"
                f"[color=#6b4f2a][b]你实际拿到[/b][/color]\n{intel_note}\n"
                f"可信度 {int(round(float(truth_profile.get('confidence', 0.5)) * 100))}%  ·  真话率 {int(round(float(truth_profile.get('truthfulness', 0.5)) * 100))}%\n\n"
                f"[color=#6b4f2a][b]世界变化[/b][/color]\n{world_effects}\n\n"
                f"[i]{npc['district']} 的风向因此更清楚了一点。[/i]"
            )
            self.state["last_dialogue"]["lines"] = lines
            self.state["last_dialogue"]["stance"] = stance
            self.state["last_dialogue"]["truthfulness"] = round(float(truth_profile.get("truthfulness", 0.5)), 3)
            self.state["last_dialogue"]["confidence"] = round(float(truth_profile.get("confidence", 0.5)), 3)
            self.state["last_dialogue"]["revealed_topic_ids"] = revealed_topic_ids
            self.state["last_dialogue"]["topic_id"] = str(topic.get("id", ""))
            self.state["last_dialogue"]["approach"] = approach
            self.state["last_dialogue"]["intent"] = intent
            self.state["last_dialogue"]["player_input"] = player_input
            self.state["last_dialogue"]["world_effects"] = world_effects
            self.state["last_dialogue"]["npc_id"] = npc_id
            self.state["last_dialogue"]["district"] = npc["district"]
            self.state["last_dialogue"]["heard_by"] = heard_by
            self.state["last_dialogue"]["source"] = "llm" if dialogue else "rule"
            self.state["last_dialogue"]["model"] = str(dialogue.get("_meta_model", self.ark.model_id)) if dialogue else "rule"
            self.state["last_dialogue"]["trade_quotes"] = trade_quotes
            self._refresh_ambient_speeches()
            self._apply_intraday_market_move(reason="player_talk", decay=0.78)
            self._refresh_derived_views()
            return ActionResult(f"你和 {npc['name']} 搭了几句线。", self.snapshot())

    def conversation(
        self,
        speaker_id: str,
        listener_id: str,
        trigger: str,
        scene_observation: dict[str, Any] | None = None,
        allow_llm: bool = True,
    ) -> ActionResult:
        with self.lock:
            speaker = self._find_npc(speaker_id)
            listener = self._find_npc(listener_id)
            now = time.time()
            if not speaker or not listener:
                return ActionResult("搭话对象不存在。", self.snapshot())
            if now < float(speaker.get("cooldown_until", 0)) or now < float(listener.get("cooldown_until", 0)):
                return ActionResult("", self.snapshot())
            if scene_observation:
                self._record_scene_observation(scene_observation)

            live_observation = copy.deepcopy(self.state.get("scene_observation", {}))
            self._refresh_derived_views()
            topic = self._resolve_talk_topic(speaker, "", speaker["district"])
            self._queue_agent_task(speaker, "npc_conversation", str(listener.get("name", "")))
            self._queue_agent_task(listener, "npc_conversation", str(speaker.get("name", "")))
            dialogue = None
            if allow_llm and self._consume_agent_budget(speaker, "npc_conversation", 1) and self._consume_agent_budget(listener, "npc_conversation", 1):
                dialogue = self.ark.generate_dialogue_turn(
                    {
                        "speaker": speaker,
                        "speaker_agent": self._npc_agent_profile(speaker),
                        "listener": listener,
                        "listener_agent": self._npc_agent_profile(listener),
                        "district": speaker["district"],
                        "trigger": trigger,
                        "topic": topic,
                        "approach": "cautious",
                        "intent": "街头搭话",
                        "scene_observation": live_observation,
                        "truth_profile": self._truth_metrics_for_topic(listener, topic, "cautious", "街头搭话"),
                        "relationship_memory": {
                            "speaker_recent_events": copy.deepcopy(list(speaker.get("relationship_memory", []))[:3]),
                            "listener_recent_events": copy.deepcopy(list(listener.get("relationship_memory", []))[:3]),
                        },
                    }
                )
            lines = None
            if dialogue:
                raw_lines = dialogue.get("lines", [])
                if isinstance(raw_lines, list) and len(raw_lines) >= 2:
                    lines = [str(raw_lines[0]), str(raw_lines[1])]
            if not lines:
                lines = self._rule_conversation_lines(speaker, listener, trigger)
            else:
                fallback_lines = self._rule_conversation_lines(speaker, listener, trigger)
                lines[0] = self._normalize_spoken_line(str(speaker.get("name", "")), lines[0], fallback_lines[0])
                lines[1] = self._normalize_spoken_line(str(listener.get("name", "")), lines[1], fallback_lines[1])
            if dialogue:
                self._remember_agent_output(speaker, "npc_conversation", lines[0])
                self._remember_agent_output(listener, "npc_conversation", lines[1])

            speaker["speech_lines"] = [lines[0], *speaker["speech_lines"][:2]]
            listener["speech_lines"] = [lines[1], *listener["speech_lines"][:2]]
            speaker["mood"] = self._shift_mood_after_talk(speaker["mood"])
            listener["mood"] = self._shift_mood_after_talk(listener["mood"])
            speaker["fear"] = min(100, speaker["fear"] + self.random.randint(0, 4))
            listener["fear"] = min(100, listener["fear"] + self.random.randint(0, 4))
            speaker["memory_tags"] = self._push_memory(speaker["memory_tags"], f"talk:{listener_id}")
            listener["memory_tags"] = self._push_memory(listener["memory_tags"], f"talk:{speaker_id}")
            self._remember_npc_event(
                speaker,
                "npc_conversation",
                {
                    "counterpart": str(listener.get("name", "")),
                    "counterpart_id": listener_id,
                    "trigger": trigger,
                    "topic_id": str(topic.get("id", "")),
                },
            )
            self._remember_npc_event(
                listener,
                "npc_conversation",
                {
                    "counterpart": str(speaker.get("name", "")),
                    "counterpart_id": speaker_id,
                    "trigger": trigger,
                    "topic_id": str(topic.get("id", "")),
                },
            )
            speaker["cooldown_until"] = now + 7
            listener["cooldown_until"] = now + 7

            self.state["local_broadcasts"].insert(
                0,
                {
                    "source": speaker["id"],
                    "district": speaker["district"],
                    "radius": max(speaker["social_radius"], listener["social_radius"]),
                    "line": lines[0],
                    "type": "conversation",
                },
            )
            self.state["local_broadcasts"] = self.state["local_broadcasts"][:18]
            self._apply_local_hearing(speaker)
            self._apply_local_hearing(listener)
            self._check_local_escalation(speaker)
            self._check_local_escalation(listener)
            conversation_intensity = max(0.22, min(0.92, float(topic.get("heat", 0.3)) * 0.55 + 0.28))
            if dialogue or float(topic.get("heat", 0.0)) >= 0.24:
                packet = self._build_intel_packet_from_topic(topic, speaker, speaker["district"])
                packet["source"] = f"{speaker['name']}和{listener['name']}的私语"
                packet["line"] = f"{speaker['name']}压着声线递话：{packet['line']}"
                packet["body"] = f"{speaker['name']}和{listener['name']}的低声交谈里冒出一句：{packet['line']}"
                promote_news = conversation_intensity >= 0.72 or str(packet.get("scope", "district")) == "city"
                self._apply_intel_packet(packet, to_player=False, promote_news=promote_news, intensity=conversation_intensity)
                self._apply_intraday_market_move(reason="npc_conversation", decay=0.84)
                self._bump_district_signal(speaker["district"], "gossip", 0.14 + float(topic.get("heat", 0.0)) * 0.08)
            self._refresh_ambient_speeches()
            self._refresh_derived_views()
            return ActionResult(f"{speaker['name']} 与 {listener['name']} 低声交换了风向。", self.snapshot())

    def hearing_event(self, speaker_id: str, listener_id: str, line: str) -> ActionResult:
        with self.lock:
            speaker = self._find_npc(speaker_id)
            listener = self._find_npc(listener_id)
            if not speaker or not listener:
                return ActionResult("", self.snapshot())
            listener["fear"] = min(100, listener["fear"] + 3)
            listener["memory_tags"] = self._push_memory(listener["memory_tags"], f"heard:{speaker_id}")
            listener["speech_lines"] = [f"有人刚提到：{line[:18]}"]
            self._check_local_escalation(listener)
            self._refresh_ambient_speeches()
            self._refresh_derived_views()
            return ActionResult("", self.snapshot())

    def _run_agent_social_turns(self, scene_observation: dict[str, Any], allow_llm: bool = True) -> None:
        rows: list[tuple[float, float, str, str]] = []
        npcs = self.state.get("npcs", [])
        for index, speaker in enumerate(npcs):
            for listener in npcs[index + 1 :]:
                if str(speaker.get("district", "")) != str(listener.get("district", "")):
                    continue
                distance = self._distance(speaker, listener)
                if distance > min(float(speaker.get("social_radius", 180)), float(listener.get("social_radius", 180))) * 0.82:
                    continue
                district_signals = self.state.get("district_signals", {}).get(str(speaker.get("district", "")), {})
                district_heat = float(district_signals.get("gossip", 0.0)) + float(district_signals.get("fear", 0.0)) + float(district_signals.get("labor_heat", 0.0))
                social_pull = float(speaker.get("proactive_interest", 0.3)) + float(listener.get("proactive_interest", 0.3))
                same_subregion_bonus = 0.22 if str(speaker.get("subregion_id", "")) == str(listener.get("subregion_id", "")) else 0.0
                role_bonus = 0.18 if str(speaker.get("role", "")) in {"记者", "代理人", "工会领袖"} else 0.0
                role_bonus += 0.18 if str(listener.get("role", "")) in {"记者", "代理人", "工会领袖"} else 0.0
                score = social_pull + district_heat * 0.24 + same_subregion_bonus + role_bonus - distance / 420.0
                rows.append((score, distance, str(speaker.get("id", "")), str(listener.get("id", ""))))
        rows.sort(key=lambda item: (item[0], -item[1]), reverse=True)
        used: set[str] = set()
        turns = 0
        max_turns = min(6, max(3, len(npcs) // 4))
        for _, _, speaker_id, listener_id in rows:
            if speaker_id in used or listener_id in used:
                continue
            speaker = self._find_npc(speaker_id)
            listener = self._find_npc(listener_id)
            if not speaker or not listener:
                continue
            self._queue_agent_task(speaker, "agent_social", str(listener.get("name", "")))
            self._queue_agent_task(listener, "agent_social", str(speaker.get("name", "")))
            trigger = "盘前试探"
            if str(speaker.get("district", "")) == "工厂区":
                trigger = "工棚低声串话"
            elif str(speaker.get("district", "")) == "港口":
                trigger = "码头换班闲聊"
            elif str(speaker.get("district", "")) == "贫民街":
                trigger = "巷口传话"
            self.conversation(speaker_id, listener_id, trigger, scene_observation=scene_observation, allow_llm=allow_llm)
            used.add(speaker_id)
            used.add(listener_id)
            turns += 1
            if turns >= max_turns:
                break

    def _load_json(self, filename: str) -> Any:
        return json.loads((DATA_DIR / filename).read_text(encoding="utf-8"))

    def _flatten_subregions(self, districts: list[dict[str, Any]]) -> list[dict[str, Any]]:
        rows: list[dict[str, Any]] = []
        for district in districts:
            district_id = str(district.get("id", ""))
            district_name = str(district.get("name", ""))
            for subregion in district.get("subregions", []):
                row = copy.deepcopy(subregion)
                row["district_id"] = district_id
                row["district_name"] = district_name
                rows.append(row)
        return rows

    def _do_work(self, district: str) -> ActionResult:
        wages = 7 if district == "港口" else 5
        player = self.state["player"]
        player["cash"] += wages
        player["credit"] = min(100, player["credit"] + 1)
        player["reputation"] = min(100, player["reputation"] + 1)
        self.state["demo_metrics"]["work_actions"] = int(self.state["demo_metrics"].get("work_actions", 0)) + 1
        self.state["macro"]["economy_heat"] = min(100, int(self.state["macro"]["economy_heat"]) + 1)
        self._bump_district_signal(district, "labor_heat", 0.2)
        self._bump_district_signal(district, "liquidity", 0.08)
        self._increment_task_progress("work", district, 1)
        return ActionResult(f"你在{district}干完一轮活，拿到 {wages} 铜币。", self.snapshot())

    def _gather_info(self, district: str) -> ActionResult:
        player = self.state["player"]
        if player["cash"] < 2:
            return ActionResult("你连买消息的钱都不够。", self.snapshot())
        player["cash"] -= 2
        intel = self._build_intel_packet(district, source="街头耳报")
        self._apply_intel_packet(intel, to_player=True, promote_news=True, intensity=1.0)
        self._increment_task_progress("gather_info", "any", 1)
        self.state["demo_metrics"]["intel_actions"] = int(self.state["demo_metrics"].get("intel_actions", 0)) + 1
        self._bump_district_signal(district, "gossip", 0.3)
        self._bump_district_signal(district, "fear", 0.08 if "恐慌" in intel.get("tags", []) else 0.0)
        self._apply_intraday_market_move(reason="gather_info", decay=0.74)
        return ActionResult(f"你从脏兮兮的墙报上抄下一条风声：{intel['line']}", self.snapshot())

    def _rest_at_home(self, district: str, payload: dict[str, Any]) -> ActionResult:
        player = self.state["player"]
        player["credit"] = min(100, player["credit"] + 2)
        player["reputation"] = min(100, player["reputation"] + 1)
        player["rumors"] = player["rumors"][-5:]
        self._advance_clock(42)
        house_title = str(payload.get("house_title", "屋子"))
        self.state["global_news"].insert(
            0,
            {
                "title": f"{district} 夜灯渐稳",
                "body": f"你在 {house_title} 的木床上歇了片刻，脑子终于没那么紧了。",
                "tags": ["休整", district],
                "scope": "district",
            },
        )
        self.state["global_news"] = self.state["global_news"][:8]
        return ActionResult(f"你在 {house_title} 的木床上缓了口气。", self.snapshot())

    def _cook_meal(self, district: str, payload: dict[str, Any]) -> ActionResult:
        player = self.state["player"]
        inventory = player["goods_inventory"]
        if inventory.get("面包", 0) > 0:
            inventory["面包"] -= 1
            meal_note = "你把面包烤热，又煮了一小锅浓汤。"
        else:
            if player["cash"] < 3:
                return ActionResult("灶台有火，但你手里连做饭的钱都快没了。", self.snapshot())
            player["cash"] -= 3
            meal_note = "你掏了 3 铜币凑出一顿热饭。"
        player["credit"] = min(100, player["credit"] + 1)
        self._advance_clock(26)
        return ActionResult(meal_note, self.snapshot())

    def _search_home(self, district: str, payload: dict[str, Any]) -> ActionResult:
        player = self.state["player"]
        roll = self.random.random()
        self._advance_clock(14)
        if roll < 0.34:
            coins = self.random.randint(2, 5)
            player["cash"] += coins
            return ActionResult(f"你在储物箱底翻出 {coins} 枚铜币。", self.snapshot())
        if roll < 0.68:
            player["goods_inventory"]["罐头"] = player["goods_inventory"].get("罐头", 0) + 1
            return ActionResult("你在旧木柜里翻出一听还没过期的罐头。", self.snapshot())
        hint = self.random.choice(self.demo_flow["intel_lines"])
        player["rumors"].append(hint)
        player["rumors"] = player["rumors"][-6:]
        return ActionResult("你在夹层里找到一张旧纸条，上面写着一条风声。", self.snapshot())

    def _review_ledger(self, district: str, payload: dict[str, Any]) -> ActionResult:
        player = self.state["player"]
        self._advance_clock(18)
        player["credit"] = min(100, player["credit"] + 1)
        hint = self.random.choice(self.demo_flow["intel_lines"])
        player["rumors"].append(hint)
        player["rumors"] = player["rumors"][-6:]
        self.state["last_dialogue"] = {
            "title": "账桌记下的新线索",
            "body": f"[b]你[/b]：把今天看到的价差、传闻和人情都记了下来。\n\n[i]{hint}[/i]",
            "tone": "conversation",
        }
        return ActionResult("你在账桌前把价格、风声和人情重新理顺了一遍。", self.snapshot())

    def _trade_good(self, good_name: str, quantity: int, direction: int, payload: dict[str, Any] | None = None) -> ActionResult:
        player = self.state["player"]
        good = self._find_by_name(self.state["goods"], good_name)
        if not good:
            return ActionResult("没有这个货物。", self.snapshot())
        payload = payload or {}
        npc: dict[str, Any] | None = None
        npc_id = str(payload.get("npc_id", ""))
        if npc_id:
            npc = self._find_npc(npc_id)
        quantity = max(quantity, 1)
        unit_price = int(good["current_price"])
        trade_tone = "按市场价"
        if npc:
            unit_price, trade_tone = self._npc_good_quote(npc, good_name, direction)
        cost = unit_price * quantity
        if direction > 0:
            if npc and int(npc.get("inventory", {}).get(good_name, 0)) < quantity:
                return ActionResult(f"{npc['name']} 手里现在没有这么多 {good_name}。", self.snapshot())
            if player["cash"] < cost:
                return ActionResult("铜币不够。", self.snapshot())
            player["cash"] -= cost
            player["goods_inventory"][good_name] = player["goods_inventory"].get(good_name, 0) + quantity
            if npc:
                npc["cash"] = int(npc.get("cash", 0)) + cost
                npc["inventory"][good_name] = max(0, int(npc.get("inventory", {}).get(good_name, 0)) - quantity)
                npc["speech_lines"] = [f"{trade_tone}，{good_name} 我先给你 {quantity} 份。", *npc.get("speech_lines", [])[:2]]
            self._increment_task_progress("trade_goods", good_name, quantity)
            self.state["demo_metrics"]["goods_trades"] = int(self.state["demo_metrics"].get("goods_trades", 0)) + quantity
            self.state["market_pressure"]["goods"][good_name] = float(self.state["market_pressure"]["goods"].get(good_name, 0.0)) + 0.05 * quantity
            self._bump_district_signal("贫民街" if good_name == "面包" else "工厂区" if good_name == "煤" else "港口", "trade_heat", 0.08 * quantity)
            self._update_player_class()
            self._refresh_derived_views()
            if npc:
                return ActionResult(f"你从 {npc['name']} 手里买下 {good_name} x{quantity}，成交价 {cost} 铜币。", self.snapshot())
            return ActionResult(f"买入 {good_name} x{quantity}。", self.snapshot())
        if player["goods_inventory"].get(good_name, 0) < quantity:
            return ActionResult("库存不足。", self.snapshot())
        if npc and int(npc.get("cash", 0)) < cost:
            return ActionResult(f"{npc['name']} 手头铜币不够，不肯接这单。", self.snapshot())
        player["goods_inventory"][good_name] -= quantity
        player["cash"] += cost
        if npc:
            npc["cash"] = max(0, int(npc.get("cash", 0)) - cost)
            npc["inventory"][good_name] = int(npc.get("inventory", {}).get(good_name, 0)) + quantity
            npc["speech_lines"] = [f"{trade_tone}，{good_name} 我收下了。", *npc.get("speech_lines", [])[:2]]
        self._increment_task_progress("trade_goods", good_name, quantity)
        self.state["demo_metrics"]["goods_trades"] = int(self.state["demo_metrics"].get("goods_trades", 0)) + quantity
        self.state["market_pressure"]["goods"][good_name] = float(self.state["market_pressure"]["goods"].get(good_name, 0.0)) - 0.04 * quantity
        self._bump_district_signal("贫民街" if good_name == "面包" else "工厂区" if good_name == "煤" else "港口", "trade_heat", 0.06 * quantity)
        self._update_player_class()
        self._refresh_derived_views()
        if npc:
            return ActionResult(f"你把 {good_name} x{quantity} 卖给了 {npc['name']}，收回 {cost} 铜币。", self.snapshot())
        return ActionResult(f"卖出 {good_name} x{quantity}。", self.snapshot())

    def _npc_good_quote(self, npc: dict[str, Any], good_name: str, direction: int) -> tuple[int, str]:
        good = self._find_by_name(self.state["goods"], good_name)
        base_price = int(good.get("current_price", 1)) if good else 1
        pressure = float(npc.get("anxiety", npc.get("fear", 0))) * 0.02
        greed = float(npc.get("greed_drive", npc.get("greed", 0))) * 0.015
        trust_discount = max(-0.12, min(0.08, (50.0 - float(npc.get("player_trust", 50.0))) / 250.0))
        if direction > 0:
            factor = 1.0 + greed + pressure + trust_discount
            tone = "要按我这口价"
        else:
            factor = 0.84 - greed * 0.12 - pressure * 0.06 - trust_discount * 0.4
            factor = max(0.55, factor)
            tone = "只能按这个价回收"
        return max(1, int(round(base_price * factor))), tone

    def _default_trade_quotes_for_npc(self, npc: dict[str, Any]) -> list[dict[str, Any]]:
        quotes: list[dict[str, Any]] = []
        inventory = copy.deepcopy(npc.get("inventory", {}))
        for action_type, good_name, quantity, prefix in [
            ("buy_goods", "面包", 1, "买"),
            ("buy_goods", "煤", 1, "买"),
            ("sell_goods", "罐头", 1, "卖"),
        ]:
            if action_type == "buy_goods" and int(inventory.get(good_name, 0)) <= 0:
                continue
            if action_type == "sell_goods" and int(self.state["player"]["goods_inventory"].get(good_name, 0)) <= 0:
                continue
            unit_price, tone = self._npc_good_quote(npc, good_name, 1 if action_type == "buy_goods" else -1)
            quotes.append(
                {
                    "action_type": action_type,
                    "good_name": good_name,
                    "quantity": quantity,
                    "unit_price": unit_price,
                    "description": f"{prefix}{good_name} x{quantity}，{tone}，单价 {unit_price} 铜币。",
                    "button": f"{prefix}{good_name}",
                }
            )
        return quotes

    def _npc_inventory_summary(self, npc: dict[str, Any]) -> str:
        inventory = copy.deepcopy(npc.get("inventory", {}))
        rows = [f"{name}:{int(inventory.get(name, 0))}" for name in ["面包", "煤", "罐头"]]
        return " / ".join(rows)

    def _trade_stock(self, stock_name: str, quantity: int, direction: int) -> ActionResult:
        player = self.state["player"]
        stock = self._find_by_name(self.state["stocks"], stock_name)
        if not stock:
            return ActionResult("没有这支股票。", self.snapshot())
        quantity = max(quantity, 1)
        cost = stock["current_price"] * quantity
        if direction > 0:
            if player["cash"] < cost:
                return ActionResult("现金不足。", self.snapshot())
            player["cash"] -= cost
            player["stock_holdings"][stock_name] = player["stock_holdings"].get(stock_name, 0) + quantity
            if stock_name == "晨报传媒":
                self._increment_task_progress("swing_trade_media", stock_name, quantity)
            self.state["demo_metrics"]["stock_trades"] = int(self.state["demo_metrics"].get("stock_trades", 0)) + quantity
            self.state["market_pressure"]["stocks"][stock_name] = float(self.state["market_pressure"]["stocks"].get(stock_name, 0.0)) + 0.06 * quantity
            self._bump_district_signal("交易所", "liquidity", 0.12 * quantity)
            self._bump_district_signal("交易所", "trade_heat", 0.08 * quantity)
            self._update_player_class()
            return ActionResult(f"买入 {stock_name} x{quantity}。", self.snapshot())
        if player["stock_holdings"].get(stock_name, 0) < quantity:
            return ActionResult("持仓不足。", self.snapshot())
        player["stock_holdings"][stock_name] -= quantity
        player["cash"] += cost
        self.state["demo_metrics"]["stock_trades"] = int(self.state["demo_metrics"].get("stock_trades", 0)) + quantity
        self.state["market_pressure"]["stocks"][stock_name] = float(self.state["market_pressure"]["stocks"].get(stock_name, 0.0)) - 0.05 * quantity
        self._bump_district_signal("交易所", "liquidity", 0.1 * quantity)
        self._bump_district_signal("交易所", "trade_heat", 0.06 * quantity)
        self._update_player_class()
        return ActionResult(f"卖出 {stock_name} x{quantity}。", self.snapshot())

    def _accept_task(self, task_id: str) -> ActionResult:
        player = self.state["player"]
        task = self._find_by_id(self.state["task_board"], task_id)
        if not task:
            return ActionResult("没有这张告示。", self.snapshot())
        player["active_task_id"] = task_id
        player["task_progress"].setdefault(task_id, 0)
        return ActionResult(f"你接下了任务：{task['title']}。", self.snapshot())

    def _claim_task(self, task_id: str) -> ActionResult:
        player = self.state["player"]
        task = self._find_by_id(self.state["task_board"], task_id)
        if not task:
            return ActionResult("没有这张告示。", self.snapshot())
        progress = int(player["task_progress"].get(task_id, 0))
        need = int(task["requirement"]["quantity"])
        if progress < need:
            return ActionResult("任务还没做够。", self.snapshot())
        reward = task["reward"]
        player["cash"] += int(reward.get("cash", 0))
        player["reputation"] = min(100, player["reputation"] + int(reward.get("reputation", 0)))
        family_name = str(reward.get("family_name", ""))
        if family_name:
            player["family_relations"][family_name] = int(player["family_relations"].get(family_name, 0)) + int(reward.get("family_relation", 0))
        player["completed_tasks"].append(task_id)
        player["active_task_id"] = ""
        self.state["task_board"] = [row for row in self.state["task_board"] if row["id"] != task_id]
        self.state["global_news"].insert(
            0,
            {
                "title": "一张告示换来了一点台阶",
                "body": f"你完成了“{task['title']}”，{family_name if family_name else '街头'} 对你的看法更不一样了。",
                "tags": ["任务", family_name if family_name else "街头"],
                "scope": "district",
            },
        )
        self.state["global_news"] = self.state["global_news"][:8]
        self._refresh_derived_views()
        return ActionResult(f"任务完成：{task['title']}。", self.snapshot())

    def _apply_macro_shift(self, event: dict[str, Any]) -> None:
        macro = self.state["macro"]
        macro["interest_rate"] = max(0.8, round(macro["interest_rate"] + self.random.uniform(-0.2, 0.3), 2))
        macro["economy_heat"] = int(max(15, min(100, macro["economy_heat"] + event["macro_effect"]["economy_heat"])))
        macro["housing_heat"] = int(max(10, min(100, macro["housing_heat"] + event["macro_effect"]["housing_heat"])))
        macro["media_sentiment"] = int(max(0, min(100, macro["media_sentiment"] + event["macro_effect"]["media_sentiment"])))
        macro["worker_unrest"] = int(max(0, min(100, macro["worker_unrest"] + event["macro_effect"]["worker_unrest"])))

    def _apply_goods_shift(self, event: dict[str, Any]) -> None:
        for good in self.state["goods"]:
            drift = self.random.uniform(-good["volatility"], good["volatility"])
            shock = event["goods_effect"].get(good["name"], 0.0)
            macro_bonus = (self.state["macro"]["worker_unrest"] - 40) * 0.01
            rumor_pressure = float(self.state["market_pressure"]["goods"].get(good["name"], 0.0))
            factor = 1.0 + drift + shock + macro_bonus + rumor_pressure * 0.8 + self._good_chain_bonus(good)
            new_price = max(1, int(round(good["current_price"] * factor)))
            good["price_trend"] = "涨" if new_price > good["current_price"] else "跌" if new_price < good["current_price"] else "平"
            good["current_price"] = new_price
            self.state["market_pressure"]["goods"][good["name"]] = rumor_pressure * 0.4

    def _apply_stock_shift(self, event: dict[str, Any]) -> None:
        for stock in self.state["stocks"]:
            drift = self.random.uniform(-stock["volatility"], stock["volatility"])
            shock = event["stock_effect"].get(stock["name"], 0.0)
            macro_bonus = self._stock_macro_bonus(stock)
            family_bonus = self._stock_family_bonus(stock)
            company_bonus = self._stock_company_bonus(stock)
            rumor_pressure = float(self.state["market_pressure"]["stocks"].get(stock["name"], 0.0))
            reference_price = float(stock.get("reference_price", stock["current_price"]))
            stock["reference_price"] = reference_price
            mispricing = (float(stock["current_price"]) - reference_price) / max(reference_price, 1.0)
            reversion = -mispricing * 0.18
            interest_drag = -max(0.0, float(self.state.get("macro", {}).get("interest_rate", 4.0)) - 4.2) * 0.008
            profit_taking = -max(0.0, mispricing - 0.22) * 0.28
            factor = 1.0 + drift + shock + macro_bonus + family_bonus + company_bonus + rumor_pressure * 0.52 + reversion + interest_drag + profit_taking
            factor = max(0.86, min(1.16, factor))
            previous_price = int(stock["current_price"])
            stock["current_price"] = max(3, int(round(stock["current_price"] * factor)))
            stock["reference_price"] = round(reference_price * 0.985 + float(stock["current_price"]) * 0.015, 3)
            stock["market_sentiment"] = "乐观" if factor > 1.02 else "恐慌" if factor < 0.98 else "谨慎"
            if stock["current_price"] == previous_price:
                stock["market_sentiment"] = "谨慎"
            self.state["market_pressure"]["stocks"][stock["name"]] = rumor_pressure * 0.38

    def _apply_family_shift(self, event: dict[str, Any]) -> None:
        relations = self.state["player"].get("family_relations", {})
        for family in self.state["families"]:
            controlled = [company for company in self.state.get("companies", []) if company.get("family_owner") == family["name"]]
            family["cash"] = int(max(60, family["cash"] + self.random.randint(-25, 40)))
            family["reputation"] = int(max(10, min(100, family["reputation"] + self.random.randint(-4, 4))))
            family["strategy"] = self.random.choice(event["family_effect"].get(family["name"], [family["strategy"]]))
            focus_stock, focus_good = self._family_focus_targets(family)
            relation = int(relations.get(family["name"], 0))
            family_pressure = self.random.uniform(-0.05, 0.09) + relation * 0.0015 + self._family_company_pressure(controlled)
            if focus_stock:
                self.state["market_pressure"]["stocks"][focus_stock] = float(self.state["market_pressure"]["stocks"].get(focus_stock, 0.0)) + family_pressure
            if focus_good:
                self.state["market_pressure"]["goods"][focus_good] = float(self.state["market_pressure"]["goods"].get(focus_good, 0.0)) + family_pressure * 0.7
            family["sector_focus"] = focus_stock or focus_good or family.get("sector_focus", family["type"])
            family["risk_appetite"] = round(max(0.05, min(0.95, float(family.get("risk_appetite", 0.5)) + family_pressure * 0.5)), 3)
            family["public_action"] = self.random.choice(
                [
                    f"盯住 {focus_stock or focus_good}",
                    "低调观望",
                    "收紧账本",
                    "拉拢街头代理人",
                    "暗中吃货",
                ]
            )
            family["hidden_action"] = self.random.choice(
                [
                    f"沿着 {focus_good or focus_stock} 放风",
                    "买通小报",
                    "压住银行口风",
                    "试探性砸盘",
                    "让代理人去试温度",
                ]
            )
            family["market_move"] = f"{'推高' if family_pressure >= 0 else '压低'} {focus_stock or focus_good}"
            if controlled:
                family["public_action"] = self._family_public_move(family, controlled, focus_stock or focus_good)
                family["hidden_action"] = self._family_hidden_move(family, controlled, focus_stock or focus_good)
            if relation >= 10:
                family["player_attitude"] = "开始把你当成能办事的人"
            elif relation <= -8:
                family["player_attitude"] = "对你留了一手"

    def _apply_district_shift(self, event: dict[str, Any]) -> None:
        for district in self.state["districts"]:
            district["state"] = event["district_effect"].get(district["name"], district["state"])

    def _append_news_for_event(self, event: dict[str, Any]) -> None:
        payload = {
            "event_name": event["name"],
            "district": event["district"],
            "macro": self.state["macro"],
            "stocks": [{s["name"]: s["current_price"]} for s in self.state["stocks"]],
            "scene_observation": self.state.get("scene_observation", {}),
        }
        generated = self.ark.generate_news_copy(payload)
        if not generated:
            generated = {
                "title": event["news_template"]["title"],
                "body": event["news_template"]["body"].format(district=event["district"]),
                "tags": event["news_template"]["tags"],
            }
        generated["scope"] = "city"
        self.state["global_news"].insert(0, generated)
        self.state["global_news"] = self.state["global_news"][:8]

    def _generate_ai_pulse(self, trigger: str) -> None:
        self.state["local_broadcasts"] = []
        for npc in self.state["npcs"]:
            self._update_npc_state(npc, trigger)
            self._generate_npc_speech(npc)
            self._apply_local_hearing(npc)
            self._check_local_escalation(npc)
        pulse_count = int(self.state.get("demo_metrics", {}).get("ai_pulses", 0))
        use_live_llm = (
            trigger != "scheduled"
            or self._full_scheduled_llm_mode()
            or pulse_count % 5 == 0
        )
        if use_live_llm:
            self._apply_llm_pulse_brief(trigger)
            self._apply_scene_director_note(trigger)
        else:
            self._apply_fallback_pulse_brief()
            self.state["scene_director_note"] = self._fallback_scene_focus()
        self._refresh_ambient_speeches()
        self._refresh_derived_views()
        self.state["last_pulse_at"] = self._now_label()

    def _update_npc_state(self, npc: dict[str, Any], trigger: str) -> None:
        district_state = self._district_state(npc["district"])
        npc["hunger"] = min(100, max(0, npc["hunger"] + self.random.randint(0, 5)))
        npc["fatigue"] = min(100, max(0, npc["fatigue"] + self.random.randint(0, 4)))
        npc["fear"] = min(100, max(0, npc["fear"] + self.random.randint(-2, 5)))
        npc["greed"] = min(100, max(0, npc["greed"] + self.random.randint(-1, 4)))
        if district_state in {"unrest", "tense"}:
            npc["fear"] = min(100, npc["fear"] + 6)
        if trigger == "end_day":
            npc["fatigue"] = max(10, npc["fatigue"] - self.random.randint(4, 10))

        if npc["fear"] >= 70:
            npc["mood"] = "anxious"
            npc["stance"] = "谨慎"
            npc["current_goal"] = "守住口粮"
            npc["action_tendency"] = "散播坏消息"
            npc["broadcast_intent"] = "fear"
        elif npc["greed"] >= 68:
            npc["mood"] = "excited"
            npc["stance"] = "激进"
            npc["current_goal"] = "抢先套利"
            npc["action_tendency"] = "追逐风口"
            npc["broadcast_intent"] = "greed"
        elif npc["loyalty"] >= 70:
            npc["mood"] = "defiant"
            npc["stance"] = "抱团"
            npc["current_goal"] = "替靠山试探街头"
            npc["action_tendency"] = "替人放话"
            npc["broadcast_intent"] = "faction"
        else:
            npc["mood"] = self.random.choice(["wary", "hopeful", "tired"])
            npc["stance"] = self.random.choice(["观望", "现实", "冷笑"])
            npc["current_goal"] = self.random.choice(["先填饱肚子", "盯住消息", "保住工作", "找条上升的缝", "别被人当垫脚石"])
            npc["action_tendency"] = self.random.choice(["低声抱怨", "左右张望", "讨价还价", "装作无事"])
            npc["broadcast_intent"] = "low"
        npc["emotion_delta"] = {"fear": self.random.randint(-1, 4), "greed": self.random.randint(-1, 3)}

    def _generate_npc_speech(self, npc: dict[str, Any]) -> None:
        mood_templates = self.dialogue_templates["moods"].get(npc["mood"], self.dialogue_templates["moods"]["wary"])
        role_templates = self.dialogue_templates["roles"].get(npc["role"], self.dialogue_templates["roles"]["工人"])
        district_templates = self.dialogue_templates["districts"].get(npc["district"], [])
        pool = mood_templates + role_templates + district_templates
        scene_observation = self.state.get("scene_observation", {})
        scene_context = scene_observation.get("scene_context", {})
        player_memory = self._npc_player_memory(npc)
        memory_summary = self._npc_memory_summary(npc)
        if scene_context.get("current_district") == npc["district"]:
            pool.extend(
                [
                    "{name}瞥了一眼那只乌龟，像在盘算 {goal}。",
                    "{name}压低声音：外来壳客在这儿晃，今天的风怕是要改。",
                    "{name}朝街口努嘴：有人在附近盯盘，别把话说太满。",
                ]
            )
        if int(player_memory.get("talk_count", 0)) > 0:
            pool.extend(
                [
                    "{name}心里还记着你上次问的事，嘴上却不肯全认。",
                    "{name}把你当成会回头的人，先掂量你这次是不是又来买消息。",
                ]
            )
        if float(player_memory.get("pressure_from_player", 0.0)) >= 1.2:
            pool.extend(
                [
                    "{name}看见你就先收住半句，像怕你又把话往死里逼。",
                    "{name}肩膀先紧了一下，像还记得你上回的压法。",
                ]
            )
        self.random.shuffle(pool)
        lines = []
        for raw in pool:
            line = raw.format(
                name=npc["name"],
                family=npc["family_affiliation"],
                district=npc["district"],
                goal=npc["current_goal"],
            )
            if line not in lines:
                lines.append(line)
            if len(lines) >= self.random.randint(2, 5):
                break
        if memory_summary:
            lines = [lines[0], f"{npc['name']}心里算盘没放下：{memory_summary}"] if lines else [f"{npc['name']}心里算盘没放下：{memory_summary}"]
        npc["speech_lines"] = lines
        npc["cadence_seconds"] = self.random.choice([3.0, 4.0, 5.0])

    def _apply_local_hearing(self, speaker: dict[str, Any]) -> None:
        if not speaker["speech_lines"]:
            return
        self.state["local_broadcasts"].append(
            {
                "source": speaker["id"],
                "district": speaker["district"],
                "radius": speaker["social_radius"],
                "line": speaker["speech_lines"][0],
                "type": speaker["broadcast_intent"],
            }
        )
        for listener in self.state["npcs"]:
            if listener["id"] == speaker["id"]:
                continue
            if listener["district"] != speaker["district"]:
                continue
            if self._distance(speaker, listener) > speaker["social_radius"]:
                continue
            listener["fear"] = min(100, listener["fear"] + max(0, speaker["emotion_delta"]["fear"]))
            listener["greed"] = min(100, listener["greed"] + max(0, speaker["emotion_delta"]["greed"]))
            listener["memory_tags"] = self._push_memory(listener["memory_tags"], f"heard:{speaker['id']}")
            if speaker["broadcast_intent"] in {"fear", "greed", "faction"} and self.random.random() < listener["rumor_susceptibility"]:
                rumor_line = f"有人在{speaker['district']}低声说：{speaker['speech_lines'][0][:18]}"
                listener["speech_lines"] = [rumor_line, *listener["speech_lines"][:2]]
        self.state["local_broadcasts"] = self.state["local_broadcasts"][:18]

    def _check_local_escalation(self, npc: dict[str, Any]) -> None:
        if npc["fear"] >= 82:
            packet = self._build_intel_packet(npc["district"], source=f"{npc['name']}散的恐慌", speaker=npc)
            packet["line"] = f"{npc['name']} 把坏消息说得像真的：{packet['line']}"
            packet["scope"] = "district"
            self._apply_intel_packet(packet, to_player=False, promote_news=True, intensity=1.15)
            event = {
                "title": f"{npc['district']} 挤兑风声",
                "body": f"{npc['district']} 有人开始囤货，{npc['name']} 把坏消息说得像真相。",
                "tags": ["恐慌", npc["district"]],
                "scope": "district",
            }
            self.state["global_news"].insert(0, event)
            self.state["global_news"] = self.state["global_news"][:8]
            npc["fear"] = 68
        elif npc["greed"] >= 84:
            packet = self._build_intel_packet(npc["district"], source=f"{npc['name']}散的口信", speaker=npc)
            packet["line"] = f"{npc['name']} 一路兜售发财口信：{packet['line']}"
            packet["scope"] = "district"
            self._apply_intel_packet(packet, to_player=False, promote_news=True, intensity=1.0)
            event = {
                "title": f"{npc['district']} 抢购声起",
                "body": f"{npc['name']} 一路兜售发财口信，附近摊位价格开始往上蹿。",
                "tags": ["投机", npc["district"]],
                "scope": "district",
            }
            self.state["global_news"].insert(0, event)
            self.state["global_news"] = self.state["global_news"][:8]
            npc["greed"] = 71

    def _record_scene_observation(self, scene_observation: dict[str, Any]) -> None:
        self.state["scene_observation"] = {
            "current_district": str(scene_observation.get("current_district", "")),
            "player_position": dict(scene_observation.get("player_position", {})),
            "scene_context": copy.deepcopy(scene_observation.get("scene_context", {})),
            "screenshot_b64": str(scene_observation.get("screenshot_b64", "")),
        }
        self.state["last_scene_capture_at"] = self._now_label()

    def _llm_scene_observation(self, observation: dict[str, Any], *, include_image: bool) -> dict[str, Any]:
        llm_observation = copy.deepcopy(observation if isinstance(observation, dict) else {})
        if not include_image:
            llm_observation["screenshot_b64"] = ""
        return llm_observation

    def _full_scheduled_llm_mode(self) -> bool:
        return "unittest" in sys.modules or os.getenv("SHELL_MARKET_FULL_SCHEDULED_LLM", "0") == "1"

    def _use_lightweight_scheduled_llm(self) -> bool:
        return not self._full_scheduled_llm_mode()

    def _apply_llm_pulse_brief(self, trigger: str) -> None:
        observation = copy.deepcopy(self.state.get("scene_observation", {}))
        payload = self._build_llm_pulse_payload(trigger, observation)
        generated = self.ark.generate_pulse_brief(payload)
        if not generated:
            self._apply_fallback_pulse_brief()
            return

        self.state["llm_pulse_summary"] = self._prefer_chinese_text(
            str(generated.get("pulse_summary", "")).strip(),
            self._fallback_pulse_summary(),
        )
        self.state["llm_market_note"] = self._prefer_chinese_text(
            str(generated.get("market_note", "")).strip(),
            self._fallback_market_note(),
        )
        self.state["llm_scene_focus"] = self._prefer_chinese_text(
            str(generated.get("scene_focus", "")).strip(),
            self._fallback_scene_focus(),
        )
        seen_npcs = self._apply_llm_npc_updates(generated.get("npc_updates", []))
        seen_families = self._apply_llm_family_updates(generated.get("family_updates", []))
        seen_companies = self._apply_llm_company_updates(generated.get("company_updates", []))
        self._refresh_all_npc_briefs(observation, seen_npcs)
        self._refresh_all_family_briefs(observation, seen_families)
        self._refresh_all_company_briefs(observation, seen_companies)
        self._apply_llm_attention_pressure()
        self._append_pulse_journal(trigger)

    def _build_llm_pulse_payload(self, trigger: str, observation: dict[str, Any]) -> dict[str, Any]:
        self._rebuild_company_states()
        self._rebuild_family_moves()
        self._rebuild_npc_truth_profile()
        npc_cards = self._build_npc_cards()
        family_moves = copy.deepcopy(self.state.get("family_moves", []))
        company_states = copy.deepcopy(self.state.get("company_states", []))
        include_image = trigger != "scheduled" or self._full_scheduled_llm_mode()
        return {
            "trigger": trigger,
            "day": self.state.get("day", 1),
            "scene_observation": self._llm_scene_observation(observation, include_image=include_image),
            "macro": copy.deepcopy(self.state.get("macro", {})),
            "district_signals": copy.deepcopy(self.state.get("district_signals", {})),
            "player": {
                "cash": int(self.state.get("player", {}).get("cash", 0)),
                "credit": int(self.state.get("player", {}).get("credit", 0)),
                "reputation": int(self.state.get("player", {}).get("reputation", 0)),
                "class_position": str(self.state.get("player", {}).get("class_position", "底层")),
                "rumors": list(self.state.get("player", {}).get("rumors", []))[-4:],
            },
            "goods": [
                {
                    "name": str(good.get("name", "")),
                    "current_price": int(good.get("current_price", 0)),
                    "price_trend": str(good.get("price_trend", "平")),
                }
                for good in self.state.get("goods", [])
            ],
            "stocks": [
                {
                    "name": str(stock.get("name", "")),
                    "current_price": int(stock.get("current_price", 0)),
                    "market_sentiment": str(stock.get("market_sentiment", "平")),
                    "family_owner": str(stock.get("family_owner", "")),
                }
                for stock in self.state.get("stocks", [])
            ],
            "families": [
                {
                    "id": str(move.get("id", "")),
                    "name": str(move.get("name", "")),
                    "public_action": str(move.get("public_action", "")),
                    "hidden_action": str(move.get("hidden_action", "")),
                    "target_asset": str(move.get("target_asset", "")),
                    "pressure_score": float(move.get("pressure_score", 0.0)),
                    "player_attitude": str(move.get("player_attitude", "")),
                    "capital_posture": str(move.get("capital_posture", "")),
                    "recent_briefs": copy.deepcopy(move.get("recent_briefs", [])),
                }
                for move in family_moves
            ],
            "companies": [
                {
                    "id": str(company.get("id", "")),
                    "name": str(company.get("name", "")),
                    "district": str(company.get("district", "")),
                    "headline": str(company.get("headline", "")),
                    "stock_name": str(company.get("stock_name", "")),
                    "operating_state": str(company.get("operating_state", "")),
                    "funding_state": str(company.get("funding_state", "")),
                    "workforce_mood": str(company.get("workforce_mood", "")),
                    "pressure_score": float(company.get("pressure_score", 0.0)),
                    "recent_briefs": copy.deepcopy(company.get("recent_briefs", [])),
                }
                for company in company_states
            ],
            "npcs": [
                {
                    "id": str(card.get("id", "")),
                    "name": str(card.get("name", "")),
                    "district": str(card.get("district", "")),
                    "role": str(card.get("role", "")),
                    "agent_prompt": str(card.get("agent_prompt", "")),
                    "agent_budget_left": int(card.get("agent_budget_left", 0)),
                    "summary": str(card.get("personal_summary", "")),
                    "memory_summary": str(card.get("memory_summary", "")),
                    "truthfulness": float(card.get("truthfulness", 0.5)),
                    "confidence": float(card.get("confidence", 0.5)),
                    "economic_pressure": float(card.get("economic_pressure", 0.0)),
                    "position_name": str(card.get("position_name", "")),
                    "position_bias": str(card.get("position_bias", "")),
                    "relation_status": str(card.get("relation_status", "")),
                    "recent_briefs": copy.deepcopy(card.get("brief_history", [])),
                }
                for card in npc_cards
            ],
        }

    def _apply_fallback_pulse_brief(self) -> None:
        self.state["llm_pulse_summary"] = self._fallback_pulse_summary()
        self.state["llm_market_note"] = self._fallback_market_note()
        self.state["llm_scene_focus"] = self._fallback_scene_focus()
        spin_map: dict[str, dict[str, Any]] = {}
        for npc in self.state.get("npcs", []):
            npc_id = str(npc.get("id", ""))
            tilt = self._npc_market_tilt(npc)
            line = str(npc.get("speech_lines", [""])[0]) if npc.get("speech_lines") else ""
            spin_map[npc_id] = {
                "line": line,
                "stance": str(npc.get("stance", "")),
                "market_tilt": tilt,
                "source": "rule",
            }
            self._append_entity_brief_history(
                "npc_brief_history",
                npc_id,
                {"line": line, "stance": str(npc.get("stance", "")), "market_tilt": tilt, "source": "rule"},
            )
        self.state["npc_spin_map"] = spin_map
        family_briefings: dict[str, dict[str, Any]] = {}
        for family in self.state.get("families", []):
            family_name = str(family.get("name", ""))
            signal = self._family_signal_from_state(family)
            family_briefings[family_name] = {
                "public_line": str(family.get("public_action", "")),
                "hidden_line": str(family.get("hidden_action", "")),
                "focus": str(family.get("strategy", "")),
                "signal": signal,
                "source": "rule",
            }
            self._append_entity_brief_history(
                "family_brief_history",
                family_name,
                {
                    "public_line": str(family.get("public_action", "")),
                    "hidden_line": str(family.get("hidden_action", "")),
                    "focus": str(family.get("strategy", "")),
                    "signal": signal,
                    "source": "rule",
                },
            )
        self.state["family_briefings"] = family_briefings
        company_briefings: dict[str, dict[str, Any]] = {}
        for company in self.state.get("company_states", []):
            company_id = str(company.get("id", ""))
            signal = self._company_signal_from_state(company)
            company_briefings[company_id] = {
                "headline": str(company.get("headline", company.get("name", ""))),
                "worker_note": str(company.get("workforce_mood", "")),
                "risk_note": str(company.get("funding_state", "")),
                "signal": signal,
                "source": "rule",
            }
            self._append_entity_brief_history(
                "company_brief_history",
                company_id,
                {
                    "headline": str(company.get("headline", company.get("name", ""))),
                    "worker_note": str(company.get("workforce_mood", "")),
                    "risk_note": str(company.get("funding_state", "")),
                    "signal": signal,
                    "source": "rule",
                },
            )
        self.state["company_briefings"] = company_briefings
        self._append_pulse_journal("fallback")

    def _apply_llm_npc_updates(self, updates: Any) -> set[str]:
        spin_map: dict[str, dict[str, Any]] = copy.deepcopy(self.state.get("npc_spin_map", {}))
        update_rows = updates if isinstance(updates, list) else []
        seen_ids: set[str] = set()
        for row in update_rows:
            if not isinstance(row, dict):
                continue
            npc_id = str(row.get("id", "")).strip()
            if not npc_id:
                continue
            npc = self._find_npc(npc_id)
            if not npc:
                continue
            seen_ids.add(npc_id)
            line = str(row.get("line", "")).strip()
            stance = str(row.get("stance", "")).strip()
            if line:
                existing = [str(value) for value in npc.get("speech_lines", []) if str(value).strip() and str(value) != line]
                npc["speech_lines"] = [line, *existing[:2]]
            if stance:
                npc["stance"] = stance
            market_tilt = self._coerce_market_tilt(str(row.get("market_tilt", "")).strip(), npc)
            spin_map[npc_id] = {
                "line": line or (str(npc.get("speech_lines", [""])[0]) if npc.get("speech_lines") else ""),
                "stance": stance or str(npc.get("stance", "")),
                "market_tilt": market_tilt,
                "source": "llm",
            }
            self._append_entity_brief_history(
                "npc_brief_history",
                npc_id,
                {
                    "line": spin_map[npc_id]["line"],
                    "stance": spin_map[npc_id]["stance"],
                    "market_tilt": market_tilt,
                    "source": "llm",
                },
            )
        for npc in self.state.get("npcs", []):
            npc_id = str(npc.get("id", ""))
            if npc_id in seen_ids or npc_id in spin_map:
                continue
            spin_map[npc_id] = {
                "line": str(npc.get("speech_lines", [""])[0]) if npc.get("speech_lines") else "",
                "stance": str(npc.get("stance", "")),
                "market_tilt": self._npc_market_tilt(npc),
                "source": "rule",
            }
        self.state["npc_spin_map"] = spin_map
        return seen_ids

    def _apply_llm_family_updates(self, updates: Any) -> set[str]:
        briefings: dict[str, dict[str, Any]] = copy.deepcopy(self.state.get("family_briefings", {}))
        update_rows = updates if isinstance(updates, list) else []
        rows_by_name = {
            str(row.get("name", "")).strip(): row
            for row in update_rows
            if isinstance(row, dict) and str(row.get("name", "")).strip()
        }
        for family in self.state.get("families", []):
            family_name = str(family.get("name", ""))
            row = rows_by_name.get(family_name, {})
            existing = briefings.get(family_name, {})
            public_line = str(row.get("public_line", "")).strip() or str(existing.get("public_line", "")) or str(family.get("public_action", ""))
            hidden_line = str(row.get("hidden_line", "")).strip() or str(existing.get("hidden_line", "")) or str(family.get("hidden_action", family.get("shadow_strategy", "")))
            focus = str(row.get("focus", "")).strip() or str(existing.get("focus", "")) or str(family.get("strategy", ""))
            signal = self._coerce_family_signal(str(row.get("signal", "")).strip() or str(existing.get("signal", "")), family)
            family["public_action"] = public_line
            family["hidden_action"] = hidden_line
            family["llm_focus"] = focus
            briefings[family_name] = {
                "public_line": public_line,
                "hidden_line": hidden_line,
                "focus": focus,
                "signal": signal,
                "source": "llm" if family_name in rows_by_name else str(existing.get("source", "rule")),
            }
            self._append_entity_brief_history(
                "family_brief_history",
                family_name,
                {
                    "public_line": public_line,
                    "hidden_line": hidden_line,
                    "focus": focus,
                    "signal": signal,
                    "source": briefings[family_name]["source"],
                },
            )
        self.state["family_briefings"] = briefings
        return set(rows_by_name.keys())

    def _apply_llm_company_updates(self, updates: Any) -> set[str]:
        briefings: dict[str, dict[str, Any]] = copy.deepcopy(self.state.get("company_briefings", {}))
        update_rows = updates if isinstance(updates, list) else []
        rows_by_id = {
            str(row.get("id", "")).strip(): row
            for row in update_rows
            if isinstance(row, dict) and str(row.get("id", "")).strip()
        }
        for company in self.state.get("company_states", []):
            company_id = str(company.get("id", ""))
            row = rows_by_id.get(company_id, {})
            existing = briefings.get(company_id, {})
            headline = str(row.get("headline", "")).strip() or str(existing.get("headline", "")) or str(company.get("headline", ""))
            worker_note = str(row.get("worker_note", "")).strip() or str(existing.get("worker_note", "")) or str(company.get("workforce_mood", ""))
            risk_note = str(row.get("risk_note", "")).strip() or str(existing.get("risk_note", "")) or str(company.get("funding_state", ""))
            signal = self._coerce_company_signal(str(row.get("signal", "")).strip() or str(existing.get("signal", "")), company)
            company["llm_headline"] = headline
            company["llm_worker_note"] = worker_note
            company["llm_risk_note"] = risk_note
            briefings[company_id] = {
                "headline": headline,
                "worker_note": worker_note,
                "risk_note": risk_note,
                "signal": signal,
                "source": "llm" if company_id in rows_by_id else str(existing.get("source", "rule")),
            }
            self._append_entity_brief_history(
                "company_brief_history",
                company_id,
                {
                    "headline": headline,
                    "worker_note": worker_note,
                    "risk_note": risk_note,
                    "signal": signal,
                    "source": briefings[company_id]["source"],
                },
            )
        self.state["company_briefings"] = briefings
        return set(rows_by_id.keys())

    def _backfill_missing_npc_briefs(self, seen_ids: set[str], observation: dict[str, Any]) -> None:
        if not self.ark.enabled:
            return
        nearby_ids = self._nearby_npc_ids(observation)
        for npc in self.state.get("npcs", []):
            npc_id = str(npc.get("id", ""))
            if not npc_id or npc_id in seen_ids:
                continue
            topic = self._resolve_talk_topic(npc, "", str(npc.get("district", "")))
            truth_profile = self._truth_metrics_for_topic(npc, topic, "cautious", "街头风声")
            cadence = self._npc_brief_cadence_pulses(npc, observation, nearby_ids)
            use_image = cadence == 1 or npc_id in nearby_ids
            generated = self.ark.generate_npc_spin(
                {
                    "npc": copy.deepcopy(npc),
                    "topic": copy.deepcopy(topic),
                    "truth_profile": truth_profile,
                    "district_signals": copy.deepcopy(self.state.get("district_signals", {}).get(str(npc.get("district", "")), {})),
                    "relationship_memory": {
                        "player_memory": copy.deepcopy(self._npc_player_memory(npc)),
                        "recent_events": copy.deepcopy(list(npc.get("relationship_memory", []))[:4]),
                    },
                    "recent_briefs": copy.deepcopy(self._entity_brief_history("npc_brief_history", npc_id)[:3]),
                    "scene_observation": self._llm_scene_observation(observation, include_image=use_image),
                }
            )
            if not generated:
                continue
            self._apply_llm_npc_updates(
                [
                    {
                        "id": npc_id,
                        "line": str((generated.get("lines", [""]) or [""])[0]),
                        "stance": str(generated.get("stance", "")),
                        "market_tilt": str(generated.get("market_tilt", "")),
                    }
                ]
            )

    def _backfill_missing_family_briefs(self, seen_names: set[str], observation: dict[str, Any]) -> None:
        if not self.ark.enabled:
            return
        for family_move in self.state.get("family_moves", []):
            family_name = str(family_move.get("name", ""))
            if not family_name or family_name in seen_names:
                continue
            generated = self.ark.generate_family_briefing(
                {
                    "family": copy.deepcopy(family_move),
                    "controlled_companies": [
                        copy.deepcopy(company)
                        for company in self.state.get("company_states", [])
                        if str(company.get("family_owner", "")) == family_name
                    ],
                    "district_signals": copy.deepcopy(self.state.get("district_signals", {})),
                    "recent_briefs": copy.deepcopy(self._entity_brief_history("family_brief_history", family_name)[:3]),
                    "scene_observation": self._llm_scene_observation(observation, include_image=False),
                }
            )
            if not generated:
                continue
            self._apply_llm_family_updates(
                [
                    {
                        "name": family_name,
                        "public_line": str(generated.get("public_line", "")),
                        "hidden_line": str(generated.get("hidden_line", "")),
                        "focus": str(generated.get("focus", "")),
                        "signal": str(generated.get("signal", "")),
                    }
                ]
            )

    def _backfill_missing_company_briefs(self, seen_ids: set[str], observation: dict[str, Any]) -> None:
        if not self.ark.enabled:
            return
        for company in self.state.get("company_states", []):
            company_id = str(company.get("id", ""))
            if not company_id or company_id in seen_ids:
                continue
            generated = self.ark.generate_company_briefing(
                {
                    "company": copy.deepcopy(company),
                    "district_signals": copy.deepcopy(self.state.get("district_signals", {}).get(str(company.get("district", "")), {})),
                    "recent_briefs": copy.deepcopy(self._entity_brief_history("company_brief_history", company_id)[:3]),
                    "scene_observation": self._llm_scene_observation(observation, include_image=False),
                }
            )
            if not generated:
                continue
            self._apply_llm_company_updates(
                [
                    {
                        "id": company_id,
                        "headline": str(generated.get("headline", "")),
                        "worker_note": str(generated.get("worker_note", "")),
                        "risk_note": str(generated.get("risk_note", "")),
                        "signal": str(generated.get("signal", "")),
                    }
                ]
            )

    def _refresh_all_npc_briefs(self, observation: dict[str, Any], seed_seen_ids: set[str] | None = None) -> None:
        if not self.ark.enabled:
            return
        seen_ids = set(seed_seen_ids or set())
        pulse_index = int(self.state.get("demo_metrics", {}).get("ai_pulses", 0))
        nearby_ids = self._nearby_npc_ids(observation)
        refreshed = 0
        refresh_cap = 4 if self._use_lightweight_scheduled_llm() else max(4, len(self.state.get("npcs", [])))
        for npc in self.state.get("npcs", []):
            if refreshed >= refresh_cap:
                break
            npc_id = str(npc.get("id", ""))
            if not npc_id:
                continue
            if npc_id in seen_ids:
                continue
            cadence = self._npc_brief_cadence_pulses(npc, observation, nearby_ids)
            last_refresh = int(npc.get("last_llm_brief_pulse", -999))
            if last_refresh >= 0 and pulse_index - last_refresh < cadence:
                continue
            topic = self._resolve_talk_topic(npc, "", str(npc.get("district", "")))
            truth_profile = self._truth_metrics_for_topic(npc, topic, "cautious", "街头风声")
            if not self._consume_agent_budget(npc, "npc_spin", 1):
                continue
            self._queue_agent_task(npc, "npc_spin", str(topic.get("label", "街头风声")))
            generated = self.ark.generate_npc_spin(
                {
                    "npc": copy.deepcopy(npc),
                    "agent_profile": self._npc_agent_profile(npc),
                    "topic": copy.deepcopy(topic),
                    "truth_profile": truth_profile,
                    "district_signals": copy.deepcopy(self.state.get("district_signals", {}).get(str(npc.get("district", "")), {})),
                    "relationship_memory": {
                        "player_memory": copy.deepcopy(self._npc_player_memory(npc)),
                        "recent_events": copy.deepcopy(list(npc.get("relationship_memory", []))[:4]),
                    },
                    "recent_briefs": copy.deepcopy(self._entity_brief_history("npc_brief_history", npc_id)[:3]),
                    "scene_observation": self._llm_scene_observation(
                        observation,
                        include_image=cadence == 1 or npc_id in nearby_ids,
                    ),
                }
            )
            if not generated:
                continue
            npc["last_llm_brief_pulse"] = pulse_index
            npc["llm_refresh_cadence"] = cadence
            self._remember_agent_output(npc, "npc_spin", str((generated.get("lines", [""]) or [""])[0]))
            self._apply_llm_npc_updates(
                [
                    {
                        "id": npc_id,
                        "line": str((generated.get("lines", [""]) or [""])[0]),
                        "stance": str(generated.get("stance", "")),
                        "market_tilt": str(generated.get("market_tilt", "")),
                    }
                ]
            )
            refreshed += 1

    def _nearby_npc_ids(self, observation: dict[str, Any]) -> set[str]:
        scene_context = observation.get("scene_context", {}) if isinstance(observation, dict) else {}
        rows = scene_context.get("nearby_npcs", []) if isinstance(scene_context, dict) else []
        nearby_ids: set[str] = set()
        if not isinstance(rows, list):
            return nearby_ids
        for row in rows:
            if not isinstance(row, dict):
                continue
            npc_id = str(row.get("id", "")).strip()
            if npc_id:
                nearby_ids.add(npc_id)
        return nearby_ids

    def _npc_brief_cadence_pulses(self, npc: dict[str, Any], observation: dict[str, Any], nearby_ids: set[str] | None = None) -> int:
        npc_id = str(npc.get("id", ""))
        nearby = npc_id in (nearby_ids or set())
        current_district = str(observation.get("current_district", "")) if isinstance(observation, dict) else ""
        npc_district = str(npc.get("district", ""))
        topic_heat = 0.0
        for topic in self._talk_topics_for_npc(npc_id, npc_district):
            topic_heat = max(topic_heat, float(topic.get("heat", 0.0)))
        profile = self.state.get("npc_truth_profile", {}).get(npc_id, {})
        economic_pressure = float(profile.get("economic_pressure", 0.0))
        memory = self._npc_player_memory(npc)
        recent_player_attention = int(memory.get("talk_count", 0)) > 0 and int(self.state.get("day", 1)) - int(memory.get("last_seen_day", 0)) <= 1
        district_signals = self.state.get("district_signals", {}).get(npc_district, {})
        district_heat = (
            float(district_signals.get("gossip", 0.0))
            + float(district_signals.get("fear", 0.0))
            + float(district_signals.get("trade_heat", 0.0))
            + float(district_signals.get("labor_heat", 0.0))
        )
        if nearby or topic_heat >= 0.55 or economic_pressure >= 0.42 or recent_player_attention:
            return 1
        if npc_district == current_district and district_heat >= 0.5:
            return 1
        if topic_heat >= 0.28 or economic_pressure >= 0.22 or npc_district == current_district:
            return 2
        stable_bias = sum(ord(ch) for ch in npc_id) % 2
        return 3 if stable_bias == 0 else 2

    def _refresh_all_family_briefs(self, observation: dict[str, Any], seed_seen_names: set[str] | None = None) -> None:
        if not self.ark.enabled:
            return
        seen_names = set(seed_seen_names or set())
        refreshed = 0
        refresh_cap = 2 if self._use_lightweight_scheduled_llm() else max(2, len(self.state.get("family_moves", [])))
        for family_move in self.state.get("family_moves", []):
            if refreshed >= refresh_cap:
                break
            family_name = str(family_move.get("name", ""))
            if not family_name:
                continue
            if family_name in seen_names:
                continue
            generated = self.ark.generate_family_briefing(
                {
                    "family": copy.deepcopy(family_move),
                    "controlled_companies": [
                        copy.deepcopy(company)
                        for company in self.state.get("company_states", [])
                        if str(company.get("family_owner", "")) == family_name
                    ],
                    "district_signals": copy.deepcopy(self.state.get("district_signals", {})),
                    "recent_briefs": copy.deepcopy(self._entity_brief_history("family_brief_history", family_name)[:3]),
                    "scene_observation": self._llm_scene_observation(observation, include_image=False),
                }
            )
            if not generated:
                continue
            self._apply_llm_family_updates(
                [
                    {
                        "name": family_name,
                        "public_line": str(generated.get("public_line", "")),
                        "hidden_line": str(generated.get("hidden_line", "")),
                        "focus": str(generated.get("focus", "")),
                        "signal": str(generated.get("signal", "")),
                    }
                ]
            )
            refreshed += 1

    def _refresh_all_company_briefs(self, observation: dict[str, Any], seed_seen_ids: set[str] | None = None) -> None:
        if not self.ark.enabled:
            return
        seen_ids = set(seed_seen_ids or set())
        refreshed = 0
        refresh_cap = 2 if self._use_lightweight_scheduled_llm() else max(2, len(self.state.get("company_states", [])))
        for company in self.state.get("company_states", []):
            if refreshed >= refresh_cap:
                break
            company_id = str(company.get("id", ""))
            if not company_id:
                continue
            if company_id in seen_ids:
                continue
            generated = self.ark.generate_company_briefing(
                {
                    "company": copy.deepcopy(company),
                    "district_signals": copy.deepcopy(self.state.get("district_signals", {}).get(str(company.get("district", "")), {})),
                    "recent_briefs": copy.deepcopy(self._entity_brief_history("company_brief_history", company_id)[:3]),
                    "scene_observation": self._llm_scene_observation(observation, include_image=False),
                }
            )
            if not generated:
                continue
            self._apply_llm_company_updates(
                [
                    {
                        "id": company_id,
                        "headline": str(generated.get("headline", "")),
                        "worker_note": str(generated.get("worker_note", "")),
                        "risk_note": str(generated.get("risk_note", "")),
                        "signal": str(generated.get("signal", "")),
                    }
                ]
            )
            refreshed += 1

    def _append_pulse_journal(self, trigger: str) -> None:
        rows = self.state.get("pulse_journal", [])
        journal = rows if isinstance(rows, list) else []
        journal.insert(
            0,
            {
                "day": int(self.state.get("day", 1)),
                "clock": self._clock_label(),
                "trigger": trigger,
                "pulse_summary": str(self.state.get("llm_pulse_summary", "")),
                "market_note": str(self.state.get("llm_market_note", "")),
                "scene_focus": str(self.state.get("llm_scene_focus", "")),
            },
        )
        self.state["pulse_journal"] = journal[:8]

    def _apply_llm_attention_pressure(self) -> None:
        for npc in self.state.get("npcs", []):
            npc_id = str(npc.get("id", ""))
            spin = self.state.get("npc_spin_map", {}).get(npc_id, {})
            if str(spin.get("source", "")) != "llm":
                continue
            tilt = self._coerce_market_tilt(str(spin.get("market_tilt", "")), npc)
            position_kind, position_name, _, _ = self._dominant_position(npc)
            district_name = str(npc.get("district", ""))
            policy = npc.get("agent_policy", {})
            style = str(policy.get("market_style", self._npc_market_style(npc)))
            weight = float(policy.get("budget_weight", 1.0))
            if position_name and position_kind == "stock":
                base_delta = 0.012 if tilt in {"bullish", "supportive"} else -0.012 if tilt in {"bearish", "panic"} else 0.0
                if "控险" in style:
                    base_delta *= 0.68
                elif "追涨杀跌" in style:
                    base_delta *= 1.18
                delta = base_delta * weight
                if delta != 0.0:
                    self.state["market_pressure"]["stocks"][position_name] = float(self.state["market_pressure"]["stocks"].get(position_name, 0.0)) + delta
            elif position_name and position_kind == "goods":
                base_delta = 0.01 if tilt in {"bullish", "supportive"} else -0.01 if tilt in {"bearish", "panic"} else 0.0
                if "保现金流" in style:
                    base_delta *= 0.72
                delta = base_delta * weight
                if delta != 0.0:
                    self.state["market_pressure"]["goods"][position_name] = float(self.state["market_pressure"]["goods"].get(position_name, 0.0)) + delta
            if tilt in {"panic", "bearish"}:
                self._bump_district_signal(district_name, "fear", 0.03)
                self._bump_district_signal(district_name, "gossip", 0.02)
            elif tilt in {"bullish", "supportive"}:
                self._bump_district_signal(district_name, "trade_heat", 0.03)
                self._bump_district_signal(district_name, "gossip", 0.02)

        for family_move in self.state.get("family_moves", []):
            family_name = str(family_move.get("name", ""))
            briefing = self.state.get("family_briefings", {}).get(family_name, {})
            if str(briefing.get("source", "")) != "llm":
                continue
            signal = self._coerce_family_signal(str(briefing.get("signal", "")), family_move)
            target_asset = str(family_move.get("target_asset", ""))
            district_name = "交易所"
            if signal == "spin":
                self.state["macro"]["media_sentiment"] = min(100, int(self.state["macro"].get("media_sentiment", 50)) + 1)
                self._bump_district_signal(district_name, "gossip", 0.05)
            elif signal == "support":
                if target_asset in self.state["market_pressure"]["stocks"]:
                    self.state["market_pressure"]["stocks"][target_asset] = float(self.state["market_pressure"]["stocks"].get(target_asset, 0.0)) + 0.016
                if target_asset in self.state["market_pressure"]["goods"]:
                    self.state["market_pressure"]["goods"][target_asset] = float(self.state["market_pressure"]["goods"].get(target_asset, 0.0)) + 0.012
                self._bump_district_signal(district_name, "liquidity", 0.04)
            elif signal in {"clampdown", "short"}:
                if target_asset in self.state["market_pressure"]["stocks"]:
                    self.state["market_pressure"]["stocks"][target_asset] = float(self.state["market_pressure"]["stocks"].get(target_asset, 0.0)) - 0.016
                if target_asset in self.state["market_pressure"]["goods"]:
                    self.state["market_pressure"]["goods"][target_asset] = float(self.state["market_pressure"]["goods"].get(target_asset, 0.0)) - 0.012
                self._bump_district_signal(district_name, "fear", 0.04)

        for company in self.state.get("company_states", []):
            company_id = str(company.get("id", ""))
            briefing = self.state.get("company_briefings", {}).get(company_id, {})
            if str(briefing.get("source", "")) != "llm":
                continue
            signal = self._coerce_company_signal(str(briefing.get("signal", "")), company)
            stock_name = str(company.get("stock_name", ""))
            district_name = str(company.get("district", ""))
            if signal == "expansion":
                if stock_name in self.state["market_pressure"]["stocks"]:
                    self.state["market_pressure"]["stocks"][stock_name] = float(self.state["market_pressure"]["stocks"].get(stock_name, 0.0)) + 0.014
                self._bump_district_signal(district_name, "trade_heat", 0.03)
                self._bump_district_signal(district_name, "liquidity", 0.02)
            elif signal == "stress":
                if stock_name in self.state["market_pressure"]["stocks"]:
                    self.state["market_pressure"]["stocks"][stock_name] = float(self.state["market_pressure"]["stocks"].get(stock_name, 0.0)) - 0.014
                self._bump_district_signal(district_name, "fear", 0.03)
            elif signal == "labor":
                self.state["macro"]["worker_unrest"] = min(100, int(self.state["macro"].get("worker_unrest", 50)) + 1)
                self._bump_district_signal(district_name, "labor_heat", 0.04)

    def _fallback_pulse_summary(self) -> str:
        hottest_district, signals = max(
            self.state.get("district_signals", {}).items(),
            key=lambda item: float(item[1].get("gossip", 0.0)) + float(item[1].get("fear", 0.0)) + float(item[1].get("trade_heat", 0.0)),
            default=("街区", {"gossip": 0.0, "fear": 0.0, "trade_heat": 0.0}),
        )
        if float(signals.get("fear", 0.0)) >= 0.3:
            return f"{hottest_district} 先紧起来了，风声比价格跑得更快。"
        if float(signals.get("trade_heat", 0.0)) >= 0.3:
            return f"{hottest_district} 正有人抢着换手，铜币和货都在挪。"
        return f"{hottest_district} 还没炸锅，但每个人都在试别人的底。"

    def _fallback_market_note(self) -> str:
        hot_good = self._top_market_move(self.state.get("goods", []), "price_trend")
        hot_stock = self._top_market_move(self.state.get("stocks", []), "market_sentiment")
        return f"{hot_good}，{hot_stock}。"

    def _fallback_scene_focus(self) -> str:
        observation = self.state.get("scene_observation", {})
        scene_context = observation.get("scene_context", {})
        district_name = str(observation.get("current_district", "街巷"))
        nearby_npcs = scene_context.get("nearby_npcs", [])
        if nearby_npcs:
            return f"{district_name} 里，{nearby_npcs[0].get('name', '有人')} 盯你的时间比摊位还久。"
        return f"{district_name} 还在动，只是没人愿意先把真话说全。"

    def _apply_scene_director_note(self, trigger: str) -> None:
        observation = self.state.get("scene_observation", {})
        generated = self.ark.generate_scene_read(
            {
                "trigger": trigger,
                "day": self.state["day"],
                "scene_observation": observation,
                "macro": self.state["macro"],
                "headlines": self.state.get("headline_news", []),
            }
        )
        note = ""
        if generated:
            note = str(generated.get("director_note", "")).strip()
            headline_title = str(generated.get("headline_title", "")).strip()
            headline_body = str(generated.get("headline_body", "")).strip()
            if headline_title and headline_body:
                self.state["global_news"].insert(
                    0,
                    {
                        "title": headline_title,
                        "body": headline_body,
                        "tags": ["场景", str(observation.get("current_district", "街区"))],
                        "scope": "district",
                    },
                )
                self.state["global_news"] = self.state["global_news"][:8]
        if not note:
            if str(self.state.get("llm_scene_focus", "")).strip():
                note = str(self.state.get("llm_scene_focus", "")).strip()
            else:
                scene_context = observation.get("scene_context", {})
                district_name = str(observation.get("current_district", "街巷"))
                nearby_npcs = scene_context.get("nearby_npcs", [])
                if nearby_npcs:
                    note = f"{district_name} 里，{nearby_npcs[0].get('name', '有人')} 正把目光往你身上压。"
                elif district_name:
                    note = f"{district_name} 的空气正在发紧，下一轮风声会更真。"
                else:
                    note = "城里照旧在转，但风向开始变了。"
        self.state["scene_director_note"] = note[:140]

    def _refresh_ambient_speeches(self) -> None:
        self.state["ambient_speeches"] = {
            npc["id"]: {"lines": npc["speech_lines"], "cadence_seconds": npc["cadence_seconds"]}
            for npc in self.state["npcs"]
        }

    def _seed_global_news(self) -> None:
        self.state["global_news"] = [
            {
                "title": "晨钟刚响，城里先涨的是面包",
                "body": "贫民街和工棚的配给越来越薄，底层今天依旧得先为口粮发愁。",
                "tags": ["面包", "底层", "开局"],
                "scope": "city",
            },
            {
                "title": "三大家族都在等别人先犯错",
                "body": "白鹭守账、灰狼压价、猫头鹰写稿，这座城还没开盘就满是心眼。",
                "tags": ["家族", "开局"],
                "scope": "city",
            },
        ]
        self._refresh_derived_views()

    def _refresh_derived_views(self) -> None:
        self.state["headline_news"] = self.state["global_news"][:3]
        self.state["house_states"] = self._build_house_states()
        self._update_player_class()
        self._rebuild_company_states()
        self._rebuild_family_moves()
        self._rebuild_npc_truth_profile()
        for npc in self.state["npcs"]:
            npc["agent_prompt"] = self._npc_agent_prompt(npc)
            npc["agent_tool_policy"] = self._npc_tool_policy(npc)
            npc["agent_policy"] = {
                **npc.get("agent_policy", {}),
                "social_style": self._npc_social_style(npc),
                "market_style": self._npc_market_style(npc),
                "agenda": self._npc_agent_agenda(npc),
                "budget_weight": round(max(0.4, min(1.8, self._npc_daily_agent_budget(npc) / 6.0)), 2),
            }
        self.state["npc_cards"] = self._build_npc_cards()
        self._rebuild_talk_topics()
        self.state["local_rumor"] = copy.deepcopy(self.state.get("rumor_log", [])[:8])
        self.state["city_news"] = self._build_city_news()
        self.state["district_topic"] = self._build_district_topic_map()
        ranked = sorted(
            self.state["npcs"],
            key=lambda npc: (npc["fear"] + npc["greed"] + npc["loyalty"]),
            reverse=True,
        )
        self.state["npc_highlights"] = [
            {
                "id": npc["id"],
                "name": npc["name"],
                "district": npc["district"],
                "mood": npc["mood"],
                "activity": npc.get("activity", ""),
                "home_state": npc.get("home_state", "away"),
                "indoor_activity": npc.get("indoor_activity", "away"),
                "home_id": npc.get("home_id", ""),
                "schedule_note": npc.get("schedule_note", ""),
                "lights_on": bool(npc.get("lights_on", False)),
                "goal": npc["current_goal"],
                "stance": npc["stance"],
                "fear": npc["fear"],
                "greed": npc["greed"],
                "line": npc["speech_lines"][0] if npc["speech_lines"] else "",
            }
            for npc in ranked[:6]
        ]
        macro = self.state["macro"]
        unrest_bias = "紧绷" if macro["worker_unrest"] >= 60 else "可控" if macro["worker_unrest"] < 50 else "升温"
        city_mood = "投机抬头" if macro["media_sentiment"] > 55 else "谨慎收缩" if macro["media_sentiment"] < 45 else "观望"
        self.state["macro_summary"] = {
            "clock_label": self._clock_label(),
            "time_period": self.state.get("time_period", "day"),
            "light_level": self.state.get("light_level", 1.0),
            "weather": copy.deepcopy(self.state.get("weather", {})),
            "weather_label": str(self.state.get("weather", {}).get("label", "晴天")),
            "interest_rate": macro["interest_rate"],
            "economy_heat": macro["economy_heat"],
            "housing_heat": macro["housing_heat"],
            "media_sentiment": macro["media_sentiment"],
            "worker_unrest": macro["worker_unrest"],
            "city_mood": city_mood,
            "unrest_bias": unrest_bias,
            "lit_houses": sum(1 for house in self.state["house_states"].values() if house.get("lights_on")),
            "scene_director_note": self.state.get("scene_director_note", ""),
            "llm_pulse_summary": self.state.get("llm_pulse_summary", ""),
            "llm_market_note": self.state.get("llm_market_note", ""),
            "llm_scene_focus": self.state.get("llm_scene_focus", ""),
            "last_scene_capture_at": self.state.get("last_scene_capture_at", "未收到"),
        }
        player = self.state["player"]
        active_task_id = str(player.get("active_task_id", ""))
        self.state["task_summary"] = {
            "active_task_id": active_task_id,
            "active_task": self._find_by_id(self.state["task_board"], active_task_id) if active_task_id else None,
            "family_relations": copy.deepcopy(player.get("family_relations", {})),
        }
        hot_good = self._top_market_move(self.state["goods"], "price_trend")
        hot_stock = self._top_market_move(self.state["stocks"], "market_sentiment")
        latest_news = self.state["headline_news"][0] if self.state["headline_news"] else {}
        latest_rumor = self.state["rumor_log"][0] if self.state["rumor_log"] else {}
        lead_topic = self.state["talk_topics"][0] if self.state["talk_topics"] else {}
        lead_institution = self.state["institution_actions"][0] if self.state.get("institution_actions") else {}
        metrics = self.state.get("demo_metrics", {})
        objective = "先在街上看一圈，摸清地形和价格。"
        if int(metrics.get("work_actions", 0)) + int(metrics.get("goods_trades", 0)) > 0:
            objective = "去打听一条风声，看看消息怎么推市场。"
        if int(metrics.get("intel_actions", 0)) > 0 or player.get("rumors"):
            objective = "去交易所买卖一支股票，感受舆论和价格联动。"
        if int(metrics.get("stock_trades", 0)) > 0:
            objective = "敲响日钟，看事件、新闻和街区状态怎么反馈。"
        if int(metrics.get("days_ended", 0)) > 0:
            objective = "Demo 闭环已经形成，可以继续试不同赚钱路径。"
        self.state["quick_hud"] = {
            "objective": objective,
            "market_flash": f"{hot_good} · {hot_stock}",
            "latest_news_title": str(latest_news.get('title', '')),
            "latest_news_body": str(latest_news.get('body', '')),
            "latest_rumor": str(latest_rumor.get('line', '')),
            "weather_label": str(self.state.get("weather", {}).get("label", "晴天")),
            "social_prompt": str(lead_topic.get("label", "")),
            "institution_flash": str(lead_institution.get("public_line", "")),
            "ai_focus": str(self.state.get("llm_pulse_summary", "")),
            "market_note": str(self.state.get("llm_market_note", "")),
        }

    def _pick_event_for_day(self) -> dict[str, Any]:
        scored: list[tuple[float, dict[str, Any]]] = []
        recent_rumors = self.state.get("rumor_log", [])[:5]
        for event in self.event_defs:
            score = 1.0 + self.random.uniform(0.0, 0.35)
            for condition in event.get("trigger_conditions", []):
                score += self._condition_score(condition)
            for rumor in recent_rumors:
                rumor_tags = rumor.get("tags", [])
                if event["district"] == rumor.get("district"):
                    score += 0.45
                if any(tag in rumor_tags for tag in event["news_template"].get("tags", [])):
                    score += 0.32
            scored.append((score, event))
        scored.sort(key=lambda row: row[0], reverse=True)
        return copy.deepcopy(scored[0][1])

    def _condition_score(self, condition: str) -> float:
        condition = str(condition).strip()
        if condition == "seasonal":
            return 0.7
        parts = condition.split()
        if len(parts) != 3:
            return 0.2
        key, operator, raw_threshold = parts
        value = float(self.state["macro"].get(key, 0))
        threshold = float(raw_threshold)
        if operator == ">":
            if value > threshold:
                return 1.1 + min(0.9, (value - threshold) / 28.0)
            return max(0.0, 0.4 - (threshold - value) / 35.0)
        if operator == "<":
            if value < threshold:
                return 1.1 + min(0.9, (threshold - value) / 28.0)
            return max(0.0, 0.4 - (value - threshold) / 35.0)
        return 0.2

    def _build_intel_packet(
        self,
        district: str,
        source: str,
        speaker: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        district_keywords = {
            "贫民街": ("贫民街", "面包", "罐头"),
            "港口": ("港口", "蓝潮航运", "航运"),
            "工厂区": ("工厂", "矿", "煤", "黑石矿业"),
            "交易所": ("楼市", "晨报传媒", "白鹭", "利息", "银行"),
        }
        pool = [
            line
            for line in self.demo_flow.get("intel_lines", [])
            if any(keyword in line for keyword in district_keywords.get(district, (district,)))
        ]
        if not pool:
            pool = list(self.demo_flow.get("intel_lines", []))
        if speaker and str(speaker.get("role", "")) == "记者":
            pool.extend([line for line in self.demo_flow.get("intel_lines", []) if "晨报" in line or "楼市" in line])
        line = self.random.choice(pool) if pool else f"{district} 今天的风向发紧，先动的是消息。"
        goods_delta: dict[str, float] = {}
        stocks_delta: dict[str, float] = {}
        macro_delta: dict[str, float] = {}
        family_delta: dict[str, float] = {}
        tags = ["传闻", district]

        def bump(bucket: dict[str, float], key: str, amount: float) -> None:
            bucket[key] = round(float(bucket.get(key, 0.0)) + amount, 3)

        if any(token in line for token in ["港口", "蓝潮航运", "停工", "船"]):
            bump(stocks_delta, "蓝潮航运", -0.09)
            bump(goods_delta, "面包", 0.05)
            bump(goods_delta, "罐头", 0.05)
            bump(macro_delta, "worker_unrest", 2.0)
            bump(family_delta, "白鹭家族", -0.06)
            tags.extend(["港口", "航运"])
        if any(token in line for token in ["工厂", "黑石矿业", "矿", "煤"]):
            bump(stocks_delta, "黑石矿业", -0.1)
            bump(goods_delta, "煤", 0.1)
            bump(macro_delta, "worker_unrest", 2.0)
            bump(family_delta, "灰狼家族", -0.05)
            tags.extend(["工厂", "矿业"])
        if any(token in line for token in ["晨报传媒", "猫头鹰", "楼市", "头条", "报"]):
            bump(stocks_delta, "晨报传媒", 0.11)
            bump(macro_delta, "media_sentiment", 5.0)
            bump(macro_delta, "housing_heat", 4.0)
            bump(family_delta, "猫头鹰家族", 0.08)
            tags.extend(["媒体", "楼市"])
        if any(token in line for token in ["利息", "银行", "白鹭"]):
            bump(macro_delta, "interest_rate", 0.12)
            bump(macro_delta, "economy_heat", -1.0)
            bump(stocks_delta, "蓝潮航运", -0.03)
            bump(family_delta, "白鹭家族", 0.04)
            tags.extend(["金融", "利率"])
        if any(token in line for token in ["面包", "罐头", "贫民街", "口粮"]):
            bump(goods_delta, "面包", 0.08)
            bump(goods_delta, "罐头", 0.06)
            bump(macro_delta, "worker_unrest", 3.0)
            tags.extend(["底层", "口粮"])

        if not goods_delta and not stocks_delta:
            fallback_good, fallback_stock = {
                "贫民街": ("面包", "晨报传媒"),
                "港口": ("罐头", "蓝潮航运"),
                "工厂区": ("煤", "黑石矿业"),
                "交易所": ("罐头", "晨报传媒"),
            }.get(district, ("面包", "蓝潮航运"))
            bump(goods_delta, fallback_good, 0.05)
            bump(stocks_delta, fallback_stock, 0.04)

        if speaker:
            role = str(speaker.get("role", ""))
            family = str(speaker.get("family_affiliation", ""))
            if role in {"记者", "投机者"}:
                bump(stocks_delta, "晨报传媒", 0.03)
                tags.append("人物")
            if role in {"工人", "临时工", "工会领袖"}:
                bump(macro_delta, "worker_unrest", 1.0)
            if family and family != "无":
                bump(family_delta, family, 0.04)
                tags.append(family)

        unique_tags = list(dict.fromkeys(tags))
        return {
            "id": f"rumor_{self.state['day']}_{len(self.state.get('rumor_log', []))}_{self.random.randint(100, 999)}",
            "district": district,
            "source": source,
            "title": f"{district} 风声",
            "line": line,
            "body": f"{source} 说：{line}",
            "tags": unique_tags,
            "scope": "city" if any(tag in unique_tags for tag in ["金融", "楼市", "媒体"]) else "district",
            "goods_delta": goods_delta,
            "stocks_delta": stocks_delta,
            "macro_delta": macro_delta,
            "family_delta": family_delta,
        }

    def _apply_intel_packet(
        self,
        packet: dict[str, Any],
        *,
        to_player: bool,
        promote_news: bool,
        intensity: float,
    ) -> None:
        self.state["rumor_log"].insert(0, copy.deepcopy(packet))
        self.state["rumor_log"] = self.state["rumor_log"][:12]

        for good_name, delta in packet.get("goods_delta", {}).items():
            current = float(self.state["market_pressure"]["goods"].get(good_name, 0.0))
            self.state["market_pressure"]["goods"][good_name] = max(-0.35, min(0.35, current + float(delta) * intensity))
        for stock_name, delta in packet.get("stocks_delta", {}).items():
            current = float(self.state["market_pressure"]["stocks"].get(stock_name, 0.0))
            self.state["market_pressure"]["stocks"][stock_name] = max(-0.35, min(0.35, current + float(delta) * intensity))
        for family_name, delta in packet.get("family_delta", {}).items():
            current = float(self.state["market_pressure"]["families"].get(family_name, 0.0))
            self.state["market_pressure"]["families"][family_name] = max(-0.35, min(0.35, current + float(delta) * intensity))
            family = self._find_by_name(self.state["families"], family_name)
            if family:
                family["hidden_action"] = f"沿着 {packet.get('district', '街区')} 的风声试探仓位"
        for key, delta in packet.get("macro_delta", {}).items():
            if key == "interest_rate":
                self.state["macro"][key] = round(max(0.8, min(5.5, float(self.state["macro"].get(key, 0.0)) + float(delta) * intensity)), 2)
            else:
                self.state["macro"][key] = int(max(0, min(100, float(self.state["macro"].get(key, 0.0)) + float(delta) * intensity)))

        if to_player:
            player = self.state["player"]
            player["rumors"].append(packet["line"])
            player["rumors"] = player["rumors"][-6:]

        self.state["local_broadcasts"].insert(
            0,
            {
                "source": packet.get("source", "rumor"),
                "district": packet.get("district", ""),
                "radius": 150,
                "line": packet.get("line", ""),
                "type": "rumor",
            },
        )
        self.state["local_broadcasts"] = self.state["local_broadcasts"][:18]

        if promote_news:
            self.state["global_news"].insert(0, self._compose_packet_news(packet))
            self.state["global_news"] = self.state["global_news"][:8]

        if packet.get("district"):
            district = self._find_by_name(self.state["districts"], packet["district"])
            if district and district.get("state") == "normal" and intensity >= 1.0:
                district["state"] = "tense"
            self._bump_district_signal(packet["district"], "gossip", 0.08 * intensity)
            if "股票" in packet.get("tags", []) or "金融" in packet.get("tags", []) or "媒体" in packet.get("tags", []):
                self._bump_district_signal(packet["district"], "liquidity", 0.06 * intensity)
            if "底层" in packet.get("tags", []) or "工厂" in packet.get("tags", []) or "港口" in packet.get("tags", []):
                self._bump_district_signal(packet["district"], "fear", 0.05 * intensity)

    def _compose_packet_news(self, packet: dict[str, Any]) -> dict[str, Any]:
        generated = self.ark.generate_news_copy(
            {
                "event_name": packet.get("title", packet.get("source", "街头风声")),
                "district": packet.get("district", ""),
                "macro": copy.deepcopy(self.state.get("macro", {})),
                "stocks": [
                    {
                        "name": str(row.get("name", "")),
                        "current_price": int(row.get("current_price", 0)),
                        "market_sentiment": str(row.get("market_sentiment", "")),
                    }
                    for row in self.state.get("stocks", [])
                ],
                "scene_observation": copy.deepcopy(self.state.get("scene_observation", {})),
                "source_line": packet.get("line", ""),
                "source_body": packet.get("body", ""),
                "tags": list(packet.get("tags", [])),
                "goods_delta": copy.deepcopy(packet.get("goods_delta", {})),
                "stocks_delta": copy.deepcopy(packet.get("stocks_delta", {})),
                "family_delta": copy.deepcopy(packet.get("family_delta", {})),
            }
        )
        if generated:
            generated["scope"] = str(packet.get("scope", generated.get("scope", "district")))
            generated["tags"] = list(generated.get("tags", packet.get("tags", [])))
            return generated
        return {
            "title": packet.get("title", "街头风声"),
            "body": packet.get("body", packet.get("line", "")),
            "tags": packet.get("tags", []),
            "scope": packet.get("scope", "district"),
        }

    def _apply_player_talk_fallout(
        self,
        npc: dict[str, Any],
        topic: dict[str, Any],
        intel: dict[str, Any],
        strength: float,
        scene_observation: dict[str, Any],
        spoken_line: str,
        approach: str,
        intent: str,
    ) -> int:
        scene_context = scene_observation.get("scene_context", {}) if isinstance(scene_observation, dict) else {}
        nearby_rows = scene_context.get("nearby_npcs", []) if isinstance(scene_context, dict) else []
        if not isinstance(nearby_rows, list):
            return 0
        heard_count = 0
        overheard_ids: list[str] = []
        nervous_topic = str(topic.get("kind", "")) in {"panic", "family", "company", "institution"}
        market_topic = str(topic.get("kind", "")) in {"asset", "company", "family", "institution"}
        for row in nearby_rows:
            if not isinstance(row, dict):
                continue
            listener_id = str(row.get("id", "")).strip()
            if not listener_id or listener_id == str(npc.get("id", "")):
                continue
            listener = self._find_npc(listener_id)
            if not listener or str(listener.get("district", "")) != str(npc.get("district", "")):
                continue
            heard_count += 1
            overheard_ids.append(listener_id)
            listener["memory_tags"] = self._push_memory(listener.get("memory_tags", []), f"heard_player:{npc.get('id', '')}")
            listener["heard_topic_ids"] = self._push_memory(listener.get("heard_topic_ids", []), str(topic.get("id", "")))
            if nervous_topic:
                listener["fear"] = min(100, int(listener.get("fear", 0)) + max(1, int(round(strength * 6))))
            if market_topic:
                listener["greed"] = min(100, int(listener.get("greed", 0)) + max(1, int(round(strength * 4))))
                self._bump_district_signal(str(listener.get("district", "")), "liquidity", 0.03 * strength)
            if strength > 0.18 and self.random.random() < min(0.95, float(listener.get("rumor_susceptibility", 0.35)) + strength * 0.35):
                listener["speech_lines"] = [f"旁边有人刚聊到：{spoken_line[:22]}", *list(listener.get("speech_lines", []))[:2]]
            self._remember_npc_event(
                listener,
                "heard_player_talk",
                {
                    "speaker": str(npc.get("name", "")),
                    "speaker_id": str(npc.get("id", "")),
                    "topic_id": str(topic.get("id", "")),
                    "approach": approach,
                    "intent": intent,
                },
            )
        if heard_count:
            self._bump_district_signal(str(npc.get("district", "")), "gossip", 0.05 * heard_count * max(0.6, strength))
        if heard_count >= 2 and strength >= 0.42:
            echoed_packet = copy.deepcopy(intel)
            echoed_packet["source"] = f"{npc.get('name', '那只动物')}身边围观的人"
            echoed_packet["title"] = f"{npc.get('district', '街区')} 围观声扩开了"
            echoed_packet["body"] = f"你和 {npc.get('name', '那只动物')} 的交谈被旁边的人听进去了：{intel.get('line', spoken_line)}"
            echoed_packet["line"] = f"围观圈里有人开始接话：{intel.get('line', spoken_line)}"
            self._apply_intel_packet(
                echoed_packet,
                to_player=False,
                promote_news=strength >= 0.78 or str(intel.get("scope", "district")) == "city",
                intensity=min(0.82, strength * 0.68),
            )
        self.state["last_dialogue_heard_by"] = overheard_ids[:4]
        return heard_count

    def _apply_intraday_market_move(self, reason: str, decay: float) -> None:
        moved: list[str] = []
        for good in self.state["goods"]:
            pressure = float(self.state["market_pressure"]["goods"].get(good["name"], 0.0))
            if abs(pressure) < 0.015:
                continue
            previous = int(good["current_price"])
            reference_price = float(good.get("reference_price", good["current_price"]))
            good["reference_price"] = reference_price
            mispricing = (float(good["current_price"]) - reference_price) / max(reference_price, 1.0)
            weather_drag = 0.02 if str(self.state.get("weather", {}).get("kind", "sunny")) in {"rain", "snow", "dust"} else 0.0
            profit_taking = max(0.0, mispricing - 0.18) * 0.16
            factor = 1.0 + pressure * 0.16 + self.random.uniform(-0.01, 0.01) - mispricing * 0.12 - weather_drag - profit_taking
            factor = max(0.92, min(1.08, factor))
            good["current_price"] = max(1, int(round(good["current_price"] * factor)))
            good["reference_price"] = round(reference_price * 0.99 + float(good["current_price"]) * 0.01, 3)
            good["price_trend"] = "涨" if good["current_price"] > previous else "跌" if good["current_price"] < previous else "平"
            if good["current_price"] != previous:
                moved.append(f"{good['name']}{good['price_trend']}到{good['current_price']}")
            self.state["market_pressure"]["goods"][good["name"]] = pressure * decay
        for stock in self.state["stocks"]:
            pressure = float(self.state["market_pressure"]["stocks"].get(stock["name"], 0.0))
            if abs(pressure) < 0.015:
                continue
            previous = int(stock["current_price"])
            reference_price = float(stock.get("reference_price", stock["current_price"]))
            stock["reference_price"] = reference_price
            mispricing = (float(stock["current_price"]) - reference_price) / max(reference_price, 1.0)
            interest_drag = max(0.0, float(self.state.get("macro", {}).get("interest_rate", 4.0)) - 4.2) * 0.006
            profit_taking = max(0.0, mispricing - 0.18) * 0.24
            factor = 1.0 + pressure * 0.14 + self.random.uniform(-0.012, 0.012) - mispricing * 0.16 - interest_drag - profit_taking
            factor = max(0.9, min(1.1, factor))
            stock["current_price"] = max(3, int(round(stock["current_price"] * factor)))
            stock["reference_price"] = round(reference_price * 0.992 + float(stock["current_price"]) * 0.008, 3)
            stock["market_sentiment"] = "乐观" if stock["current_price"] > previous else "恐慌" if stock["current_price"] < previous else "谨慎"
            if stock["current_price"] != previous:
                moved.append(f"{stock['name']}{'涨' if stock['current_price'] > previous else '跌'}到{stock['current_price']}")
            self.state["market_pressure"]["stocks"][stock["name"]] = pressure * decay
        if moved and reason in {"gather_info", "player_talk", "ai_pulse", "npc_conversation"}:
            self.state["global_news"].insert(
                0,
                {
                    "title": "盘口先动了一下",
                    "body": "、".join(moved[:3]) + "，消息已经开始写进价格。",
                    "tags": ["盘口", "风声"],
                    "scope": "district",
                },
            )
            self.state["global_news"] = self.state["global_news"][:8]

    def _bump_district_signal(self, district_name: str, key: str, amount: float) -> None:
        signals = self.state.get("district_signals", {}).get(district_name)
        if not signals or key not in signals:
            return
        signals[key] = max(0.0, min(5.0, float(signals.get(key, 0.0)) + amount))

    def _decay_district_signals(self) -> None:
        for signal_map in self.state.get("district_signals", {}).values():
            for key, value in signal_map.items():
                signal_map[key] = round(float(value) * 0.74, 3)

    def _resolve_talk_topic(self, npc: dict[str, Any], topic_id: str, district_name: str) -> dict[str, Any]:
        topic = self._find_by_id(self.state.get("talk_topics", []), topic_id) if topic_id else None
        if topic and (not topic.get("npc_ids") or npc["id"] in topic.get("npc_ids", [])):
            return topic
        npc_topics = self._talk_topics_for_npc(npc["id"], district_name)
        if npc_topics:
            return npc_topics[0]
        return {
            "id": "generic_wind",
            "kind": "rumor",
            "district": district_name,
            "label": f"{district_name} 风向",
            "summary": f"{district_name} 眼下每个人都在看别人先怎么动。",
            "heat": 1.0,
            "npc_ids": [npc["id"]],
            "impacts": {},
            "approaches": ["cautious", "friendly", "hardball"],
        }

    def _evaluate_talk_approach(self, npc: dict[str, Any], topic: dict[str, Any], approach: str) -> tuple[int, float, str]:
        relation = int(npc.get("player_relation", 0))
        role = str(npc.get("role", ""))
        memory = self._npc_player_memory(npc)
        sensitivity = 0
        if topic.get("kind") in {"family", "panic", "company"}:
            sensitivity += 1
        if role in {"代理人", "银行经理", "老板"}:
            sensitivity += 1
        if approach == "friendly":
            trust_delta = 2 if role in {"工人", "临时工", "店主", "记者"} else 1
            intel_strength = 1.0 if relation >= 0 else 0.8
            intel_strength += min(0.12, float(memory.get("trust_streak", 0)) * 0.02)
            openness = "open"
        elif approach == "hardball":
            trust_delta = -1 if sensitivity > 0 else 0
            intel_strength = 0.35 if sensitivity > 0 and relation < 5 else 0.72
            intel_strength -= min(0.18, float(memory.get("pressure_from_player", 0.0)) * 0.03)
            openness = "guarded" if sensitivity > 0 else "skeptical"
        else:
            trust_delta = 1
            intel_strength = 0.88 if relation >= -1 else 0.72
            intel_strength += min(0.08, int(memory.get("intel_bought", 0)) * 0.015)
            openness = "skeptical" if sensitivity > 0 else "open"
        return trust_delta, intel_strength, openness

    def _npc_player_memory(self, npc: dict[str, Any]) -> dict[str, Any]:
        memory = npc.get("player_memory", {})
        return memory if isinstance(memory, dict) else {}

    def _remember_player_talk(
        self,
        npc: dict[str, Any],
        topic: dict[str, Any],
        approach: str,
        intent: str,
        trust_delta: int,
        effective_strength: float,
    ) -> None:
        memory = self._npc_player_memory(npc)
        memory["talk_count"] = int(memory.get("talk_count", 0)) + 1
        if approach == "friendly":
            memory["friendly_count"] = int(memory.get("friendly_count", 0)) + 1
        if approach == "hardball":
            memory["hardball_count"] = int(memory.get("hardball_count", 0)) + 1
            memory["pressure_from_player"] = round(min(4.0, float(memory.get("pressure_from_player", 0.0)) + 0.75), 2)
        else:
            memory["pressure_from_player"] = round(max(0.0, float(memory.get("pressure_from_player", 0.0)) - 0.18), 2)
        if effective_strength >= 0.3:
            memory["intel_bought"] = int(memory.get("intel_bought", 0)) + 1
        streak = int(memory.get("trust_streak", 0))
        if trust_delta > 0:
            streak += 1
        elif trust_delta < 0:
            streak = max(0, streak - 1)
        memory["trust_streak"] = min(8, streak)
        memory["last_topic_id"] = str(topic.get("id", ""))
        memory["last_intent"] = intent
        memory["last_approach"] = approach
        memory["last_seen_day"] = int(self.state.get("day", 1))
        npc["player_memory"] = memory
        self._remember_npc_event(
            npc,
            "player_talk",
            {
                "topic_id": str(topic.get("id", "")),
                "topic_label": str(topic.get("label", "")),
                "approach": approach,
                "intent": intent,
                "sold_info": effective_strength >= 0.3,
                "trust_delta": trust_delta,
            },
        )

    def _remember_npc_event(self, npc: dict[str, Any], kind: str, payload: dict[str, Any]) -> None:
        memory_rows = npc.get("relationship_memory", [])
        rows = memory_rows if isinstance(memory_rows, list) else []
        entry = {
            "kind": kind,
            "day": int(self.state.get("day", 1)),
            "clock": self._clock_label(),
        }
        entry.update(payload)
        rows.insert(0, entry)
        npc["relationship_memory"] = rows[:8]

    def _entity_brief_history(self, bucket_name: str, entity_id: str) -> list[dict[str, Any]]:
        bucket = self.state.get(bucket_name, {})
        if not isinstance(bucket, dict):
            return []
        rows = bucket.get(entity_id, [])
        return rows if isinstance(rows, list) else []

    def _append_entity_brief_history(self, bucket_name: str, entity_id: str, entry: dict[str, Any], limit: int = 4) -> None:
        if not entity_id:
            return
        bucket = self.state.setdefault(bucket_name, {})
        if not isinstance(bucket, dict):
            bucket = {}
            self.state[bucket_name] = bucket
        rows = bucket.get(entity_id, [])
        if not isinstance(rows, list):
            rows = []
        next_entry = {
            "day": int(self.state.get("day", 1)),
            "clock": self._clock_label(),
        }
        next_entry.update(entry)
        rows.insert(0, next_entry)
        bucket[entity_id] = rows[:limit]

    @staticmethod
    def _brief_history_summary(rows: list[dict[str, Any]], keys: tuple[str, ...]) -> str:
        if not rows:
            return ""
        latest = rows[0] if isinstance(rows[0], dict) else {}
        for key in keys:
            value = str(latest.get(key, "")).strip()
            if value:
                return value
        return ""

    def _npc_memory_summary(self, npc: dict[str, Any]) -> str:
        memory = self._npc_player_memory(npc)
        rows = npc.get("relationship_memory", [])
        last_topic = str(memory.get("last_topic_id", ""))
        if last_topic.startswith("topic_"):
            last_topic = last_topic.replace("topic_", "", 1)
        sold_count = int(memory.get("intel_bought", 0))
        pressure = float(memory.get("pressure_from_player", 0.0))
        streak = int(memory.get("trust_streak", 0))
        summary = f"你问过 {int(memory.get('talk_count', 0))} 次"
        if sold_count > 0:
            summary += f" · 卖过你 {sold_count} 次消息"
        if pressure > 0.1:
            summary += f" · 被你压过 {int(round(pressure * 10))}/40"
        if streak > 0:
            summary += f" · 连着给过你 {streak} 次面子"
        if rows and isinstance(rows, list):
            latest = rows[0] if isinstance(rows[0], dict) else {}
            latest_topic = str(latest.get("topic_label", latest.get("trigger", latest.get("counterpart", ""))))
            if latest_topic:
                summary += f" · 最近记着 {latest_topic}"
        elif last_topic:
            summary += f" · 最近记着 {last_topic}"
        return summary

    def _npc_player_status(self, npc: dict[str, Any]) -> str:
        memory = self._npc_player_memory(npc)
        pressure = float(memory.get("pressure_from_player", 0.0))
        sold_count = int(memory.get("intel_bought", 0))
        friendly_count = int(memory.get("friendly_count", 0))
        trust_streak = int(memory.get("trust_streak", 0))
        talk_count = int(memory.get("talk_count", 0))
        if pressure >= 1.4:
            return "防着你"
        if sold_count >= 2 and trust_streak >= 1:
            return "愿意卖消息"
        if friendly_count >= 2 or trust_streak >= 2:
            return "愿意继续聊"
        if talk_count > 0:
            return "记得你来问过"
        return "还在观察你"

    def _npc_market_tilt(self, npc: dict[str, Any]) -> str:
        position_kind, _, _, position_bias = self._dominant_position(npc)
        anxiety = float(npc.get("anxiety", npc.get("fear", 0.0)))
        greed = float(npc.get("greed_drive", npc.get("greed", 0.0)))
        if position_kind == "stock":
            if position_bias == "鍠婂":
                return "bullish"
            if position_bias == "鍠婄┖":
                return "bearish"
        if position_kind == "goods":
            if position_bias == "鍥ょ潃":
                return "panic"
            if position_bias == "鎵句环宸?":
                return "supportive"
        if anxiety - greed >= 12:
            return "panic"
        if greed - anxiety >= 12:
            return "bullish"
        return "neutral"

    def _coerce_market_tilt(self, value: str, npc: dict[str, Any]) -> str:
        normalized = value.strip().lower()
        if normalized in {"bullish", "bearish", "panic", "supportive", "neutral"}:
            return normalized
        return self._npc_market_tilt(npc)

    def _family_signal_from_state(self, family: dict[str, Any]) -> str:
        family_name = str(family.get("name", ""))
        move = self._find_by_name(self.state.get("family_moves", []), family_name)
        if move:
            target_asset = str(move.get("target_asset", ""))
            if int(family.get("media_power", 0)) >= 60 and float(move.get("pressure_score", 0.0)) >= 0.45:
                return "spin"
            if target_asset and int(move.get("relation", 0)) <= -2:
                return "short"
            if target_asset and float(family.get("risk_appetite", 0.5)) >= 0.62:
                return "support"
        liquidity_preference = float(family.get("liquidity_preference", 0.5))
        risk_appetite = float(family.get("risk_appetite", 0.5))
        if liquidity_preference >= 0.62:
            return "clampdown"
        if risk_appetite >= 0.62:
            return "support"
        return "steady"

    def _coerce_family_signal(self, value: str, family: dict[str, Any]) -> str:
        normalized = value.strip().lower()
        if normalized in {"steady", "spin", "support", "short", "clampdown"}:
            return normalized
        return self._family_signal_from_state(family)

    def _company_signal_from_state(self, company: dict[str, Any]) -> str:
        operating_state = str(company.get("operating_state", ""))
        funding_state = str(company.get("funding_state", ""))
        workforce_mood = str(company.get("workforce_mood", ""))
        if "expanding" in operating_state:
            return "expansion"
        if "dry" in funding_state or "tight" in funding_state:
            return "stress"
        if workforce_mood in {"restless", "angry", "fragile"}:
            return "labor"
        return "steady"

    def _coerce_company_signal(self, value: str, company: dict[str, Any]) -> str:
        normalized = value.strip().lower()
        if normalized in {"steady", "expansion", "stress", "labor"}:
            return normalized
        return self._company_signal_from_state(company)

    def _approach_label(self, approach: str) -> str:
        return {
            "cautious": "试探着问",
            "friendly": "先拉近关系",
            "hardball": "直接逼问",
        }.get(approach, approach)

    def _build_intel_packet_from_topic(self, topic: dict[str, Any], npc: dict[str, Any], district_name: str) -> dict[str, Any]:
        packet = self._build_intel_packet(district_name, source=f"{npc['name']}的口风", speaker=npc)
        packet["title"] = str(topic.get("label", packet["title"]))
        packet["body"] = f"{npc['name']} 提起：{topic.get('summary', packet['body'])}"
        packet["line"] = str(topic.get("summary", packet["line"]))
        impacts = topic.get("impacts", {})
        packet["goods_delta"] = copy.deepcopy(impacts.get("goods", packet.get("goods_delta", {})))
        packet["stocks_delta"] = copy.deepcopy(impacts.get("stocks", packet.get("stocks_delta", {})))
        packet["macro_delta"] = copy.deepcopy(impacts.get("macro", packet.get("macro_delta", {})))
        packet["family_delta"] = copy.deepcopy(impacts.get("families", packet.get("family_delta", {})))
        packet["tags"] = list(dict.fromkeys(list(topic.get("tags", [])) + list(packet.get("tags", []))))
        return packet

    def _talk_topics_for_npc(self, npc_id: str, district_name: str = "") -> list[dict[str, Any]]:
        topics = self.state.get("talk_topics", [])
        filtered = []
        for topic in topics:
            npc_ids = topic.get("npc_ids", [])
            if npc_ids and npc_id not in npc_ids:
                continue
            if district_name and topic.get("district") not in {"", district_name}:
                continue
            filtered.append(topic)
        filtered.sort(key=lambda item: float(item.get("heat", 0.0)), reverse=True)
        return filtered[:4]

    def _rebuild_talk_topics(self) -> None:
        topics: list[dict[str, Any]] = []
        for district in self.state["districts"]:
            district_name = str(district.get("name", ""))
            signals = self.state["district_signals"].get(district_name, {})
            local_npcs = [npc for npc in self.state["npcs"] if npc.get("district") == district_name]
            topic_npc_ids = [npc["id"] for npc in local_npcs]
            if not district_name:
                continue
            trade_heat = float(signals.get("trade_heat", 0.0))
            labor_heat = float(signals.get("labor_heat", 0.0))
            gossip = float(signals.get("gossip", 0.0))
            fear = float(signals.get("fear", 0.0))
            liquidity = float(signals.get("liquidity", 0.0))
            if trade_heat > 0.35:
                good = max(self.state["goods"], key=lambda row: abs(float(self.state["market_pressure"]["goods"].get(row["name"], 0.0))))
                topics.append(
                    {
                        "id": f"topic_trade_{district_name}",
                        "kind": "trade",
                        "district": district_name,
                        "label": f"{district_name} 的{good['name']}价差",
                        "summary": f"{district_name} 正有人围着 {good['name']} 议价，货和铜币都开始挪位置。",
                        "heat": round(trade_heat, 3),
                        "tags": ["交易", district_name, good["name"]],
                        "npc_ids": topic_npc_ids,
                        "approaches": ["cautious", "friendly", "hardball"],
                        "impacts": {
                            "goods": {good["name"]: 0.06},
                            "stocks": {},
                            "macro": {"economy_heat": 1.0},
                            "families": {},
                        },
                    }
                )
            if labor_heat > 0.28:
                topics.append(
                    {
                        "id": f"topic_job_{district_name}",
                        "kind": "labor",
                        "district": district_name,
                        "label": f"{district_name} 的活路",
                        "summary": f"{district_name} 眼下活路紧不紧，已经写在工牌和脸色上了。",
                        "heat": round(labor_heat, 3),
                        "tags": ["工作", district_name],
                        "npc_ids": [npc["id"] for npc in local_npcs if str(npc.get("role", "")) in {"工人", "临时工", "店主", "老板"}],
                        "approaches": ["friendly", "cautious", "hardball"],
                        "impacts": {
                            "goods": {},
                            "stocks": {},
                            "macro": {"worker_unrest": 1.0 if district.get("state") in {"tense", "unrest"} else -0.5},
                            "families": {},
                        },
                    }
                )
            if gossip > 0.22 or fear > 0.2:
                topics.append(
                    {
                        "id": f"topic_panic_{district_name}",
                        "kind": "panic",
                        "district": district_name,
                        "label": f"{district_name} 的风声在变厚",
                        "summary": f"{district_name} 的耳语变密了，大家都在比谁先听见坏消息。",
                        "heat": round(gossip + fear, 3),
                        "tags": ["传闻", district_name],
                        "npc_ids": topic_npc_ids,
                        "approaches": ["cautious", "hardball", "friendly"],
                        "impacts": {
                            "goods": {"罐头": 0.04} if district_name != "工厂区" else {"煤": 0.05},
                            "stocks": {},
                            "macro": {"worker_unrest": 1.4, "media_sentiment": 0.8},
                            "families": {},
                        },
                    }
                )
            if liquidity > 0.22 or district_name == "交易所":
                hot_stock = max(self.state["stocks"], key=lambda row: abs(float(self.state["market_pressure"]["stocks"].get(row["name"], 0.0))))
                topics.append(
                    {
                        "id": f"topic_asset_{district_name}",
                        "kind": "asset",
                        "district": district_name,
                        "label": f"{hot_stock['name']} 的盘口",
                        "summary": f"{hot_stock['name']} 最近的价差和情绪走得比街上脚步还快。",
                        "heat": round(liquidity + 0.2, 3),
                        "tags": ["股票", district_name, hot_stock["name"]],
                        "npc_ids": [npc["id"] for npc in local_npcs if str(npc.get("role", "")) in {"记者", "投机者", "代理人", "银行经理", "老板"}],
                        "approaches": ["cautious", "hardball", "friendly"],
                        "impacts": {
                            "goods": {},
                            "stocks": {hot_stock["name"]: 0.07},
                            "macro": {"media_sentiment": 1.0},
                            "families": {},
                        },
                    }
                )
        for family in self.state["families"]:
            family_name = str(family.get("name", ""))
            family_pressure = abs(float(self.state["market_pressure"]["families"].get(family_name, 0.0)))
            if family_pressure < 0.05:
                continue
            stock_name, good_name = self._family_focus_targets(family)
            family_npcs = [npc["id"] for npc in self.state["npcs"] if str(npc.get("family_affiliation", "")) == family_name]
            district_name = "交易所" if stock_name or family_name != "街头互助会" else "贫民街"
            topics.append(
                {
                    "id": f"topic_family_{family.get('id', family_name)}",
                    "kind": "family",
                    "district": district_name,
                    "label": f"{family_name} 在做什么",
                    "summary": f"{family_name} 最近像是在围着 {stock_name or good_name or '街头温度'} 悄悄挪仓。",
                    "heat": round(family_pressure + 0.2, 3),
                    "tags": ["家族", family_name],
                    "npc_ids": family_npcs,
                    "approaches": ["friendly", "cautious", "hardball"],
                    "impacts": {
                        "goods": {good_name: 0.05} if good_name else {},
                        "stocks": {stock_name: 0.06} if stock_name else {},
                        "macro": {"media_sentiment": 0.6},
                        "families": {family_name: 0.08},
                    },
                }
            )
        for company in self.state.get("company_states", []):
            wage_pressure = float(company.get("wage_pressure", 0.0))
            financing_pressure = float(company.get("financing_pressure", 0.0))
            if max(wage_pressure, financing_pressure) < 45:
                continue
            company_npc_ids = [
                npc["id"]
                for npc in self.state["npcs"]
                if str(npc.get("company_id", "")) == str(company.get("id", ""))
                or (not str(npc.get("company_id", "")) and str(npc.get("district", "")) == str(company.get("district", "")))
            ]
            topics.append(
                {
                    "id": f"topic_company_{company.get('id', '')}",
                    "kind": "company",
                    "district": str(company.get("district", "")),
                    "label": f"{company.get('name', '公司')} 的账和人",
                    "summary": f"{company.get('name', '这家公司')} 眼下库存、工资和融资一起拧着，谁都不肯先认怂。",
                    "heat": round(max(wage_pressure, financing_pressure) / 100.0 + 0.18, 3),
                    "tags": ["公司", str(company.get("name", "")), str(company.get("stock_name", ""))],
                    "npc_ids": company_npc_ids,
                    "approaches": ["friendly", "cautious", "hardball"],
                    "impacts": {
                        "goods": self._company_topic_goods_impact(company),
                        "stocks": {str(company.get("stock_name", "")): 0.05} if str(company.get("stock_name", "")) else {},
                        "macro": {"worker_unrest": 0.9 if wage_pressure >= financing_pressure else 0.2, "economy_heat": -0.4},
                        "families": {str(company.get("family_owner", "")): 0.05} if str(company.get("family_owner", "")) else {},
                    },
                }
            )
        for npc in self.state["npcs"]:
            topics.extend(self._npc_personal_topics(npc))
        topics.extend(self._institution_topics())
        topics.sort(key=lambda item: float(item.get("heat", 0.0)), reverse=True)
        self.state["talk_topics"] = topics[:12]

    def _top_market_move(self, rows: list[dict[str, Any]], sentiment_key: str) -> str:
        if not rows:
            return "市场还安静"
        row = max(rows, key=lambda item: abs(int(item.get("current_price", 0)) - int(item.get("base_price", 0))))
        if sentiment_key == "price_trend":
            return f"{row['name']} {row.get('price_trend', '平')} {row['current_price']}"
        mood = row.get("market_sentiment", "谨慎")
        return f"{row['name']} {mood} {row['current_price']}"

    def _update_player_class(self) -> None:
        player = self.state["player"]
        goods_value = sum(int(good.get("current_price", 0)) * int(player["goods_inventory"].get(good["name"], 0)) for good in self.state["goods"])
        stocks_value = sum(int(stock.get("current_price", 0)) * int(player["stock_holdings"].get(stock["name"], 0)) for stock in self.state["stocks"])
        total_wealth = int(player.get("cash", 0)) + goods_value + stocks_value
        if total_wealth >= 120 or int(player.get("reputation", 0)) >= 28:
            player["class_position"] = "街头投机客"
        elif total_wealth >= 70 or int(player.get("credit", 0)) >= 35:
            player["class_position"] = "攒钱中的小人物"
        else:
            player["class_position"] = "底层"

    def _family_focus_targets(self, family: dict[str, Any]) -> tuple[str, str]:
        name = str(family.get("name", ""))
        if name == "白鹭家族":
            return "蓝潮航运", "罐头"
        if name == "灰狼家族":
            return "黑石矿业", "煤"
        if name == "猫头鹰家族":
            return "晨报传媒", "面包"
        return "", ""

    def _district_state(self, district_name: str) -> str:
        for district in self.state["districts"]:
            if district["name"] == district_name:
                return district["state"]
        return "normal"

    def _find_by_name(self, rows: list[dict[str, Any]], name: str) -> dict[str, Any] | None:
        for row in rows:
            if row["name"] == name:
                return row
        return None

    def _find_npc(self, npc_id: str) -> dict[str, Any] | None:
        for npc in self.state["npcs"]:
            if npc["id"] == npc_id:
                return npc
        return None

    def _find_by_id(self, rows: list[dict[str, Any]], row_id: str) -> dict[str, Any] | None:
        for row in rows:
            if row["id"] == row_id:
                return row
        return None

    def _increment_task_progress(self, action_type: str, target: str, amount: int) -> None:
        player = self.state["player"]
        active_task_id = str(player.get("active_task_id", ""))
        if not active_task_id:
            return
        task = self._find_by_id(self.state["task_board"], active_task_id)
        if not task:
            return
        requirement = task["requirement"]
        if requirement["type"] != action_type:
            return
        if requirement["target"] not in {"any", target}:
            return
        current = int(player["task_progress"].get(active_task_id, 0))
        player["task_progress"][active_task_id] = current + amount

    def _rule_conversation_lines(self, speaker: dict[str, Any], listener: dict[str, Any], trigger: str) -> list[str]:
        options = [
            [f"{speaker['name']}：{trigger}可不是白来的，今天的风比账本更会骗人。", f"{listener['name']}：我只想知道下一个倒霉的是面包还是矿井。"],
            [f"{speaker['name']}：你听见没有，{speaker['family_affiliation']} 的人已经在街角放话了。", f"{listener['name']}：那就说明他们想让别人先恐慌。"],
            [f"{speaker['name']}：这城里最贵的不是货，是比别人早半拍的消息。", f"{listener['name']}：慢半拍的人，通常连壳都保不住。"],
        ]
        return self.random.choice(options)

    def _rule_player_talk_lines(
        self,
        npc: dict[str, Any],
        topic: dict[str, Any],
        approach: str,
        openness: str,
        intent: str = "",
    ) -> list[str]:
        player_line = {
            "cautious": f"我只想问一句，{topic.get('label', npc['district'])} 最近是不是在变？",
            "friendly": f"我不是来压你话的，就想听听你怎么看 {topic.get('label', npc['district'])}。",
            "hardball": f"别绕了，{topic.get('label', npc['district'])} 到底是谁在做局？",
        }.get(approach, f"最近 {topic.get('label', npc['district'])} 的风向到底怎么走？")
        if openness == "guarded":
            reply = f"{npc['name']}：你先别把话说满，这话题在 {npc['district']} 不便宜。"
        elif openness == "skeptical":
            reply = f"{npc['name']}：想问就问，但我只说半句，剩下半句你自己拿壳去试。"
        else:
            reply = self.random.choice(
                [
                    f"{npc['name']}：{topic.get('summary', '街上都在看这件事。')}",
                    f"{npc['name']}：盯着 {topic.get('label', npc['district'])} 的不只你一个，慢半拍就只能接别人丢下的壳。",
                    f"{npc['name']}：真相没那么直，但 {topic.get('label', npc['district'])} 这事已经把街上气味带歪了。",
                ]
            )
        return [player_line, reply]

    def _shift_mood_after_talk(self, current: str) -> str:
        mapping = {"wary": "anxious", "hopeful": "excited", "tired": "wary", "excited": "defiant", "anxious": "wary"}
        return mapping.get(current, "wary")

    def _distance(self, a: dict[str, Any], b: dict[str, Any]) -> float:
        return ((a["x"] - b["x"]) ** 2 + (a["y"] - b["y"]) ** 2) ** 0.5

    def _advance_realtime_clock(self) -> None:
        last_tick = float(self.state.get("last_tick_at", time.time()))
        now = time.time()
        elapsed = max(0.0, now - last_tick)
        if elapsed < 1.0:
            self.state["last_tick_at"] = now
            return
        self.state["last_tick_at"] = now
        self._advance_clock(int(elapsed * 5.0))

    def _advance_clock(self, minutes: int) -> None:
        if minutes <= 0:
            return
        current = int(self.state.get("clock_minutes", 8 * 60))
        self.state["clock_minutes"] = min(23 * 60 + 45, current + minutes)
        self._apply_clock_state()
        self._apply_npc_schedule()

    def _apply_clock_state(self) -> None:
        minutes = int(self.state.get("clock_minutes", 8 * 60))
        weather = self._update_weather(minutes)
        solar_ratio = max(0.0, math.cos((float(minutes) - 720.0) / 720.0 * math.pi))
        if minutes < 5 * 60 or minutes >= 20 * 60:
            period = "night"
        elif minutes < 7 * 60:
            period = "dawn"
        elif minutes < 17 * 60:
            period = "day"
        else:
            period = "evening"
        weather_dim = {
            "sunny": 0.0,
            "breezy": 0.01,
            "cloudy": 0.04,
            "overcast": 0.08,
            "rain": 0.11,
            "snow": 0.09,
            "dust": 0.14,
        }.get(str(weather.get("kind", "sunny")), 0.0)
        light = round(max(0.18, min(1.0, 0.18 + solar_ratio * 0.82 - weather_dim)), 2)
        self.state["time_period"] = period
        self.state["light_level"] = light

    def _update_weather(self, minutes: int) -> dict[str, Any]:
        day = int(self.state.get("day", 1))
        slot = int(minutes // 180)
        current = self.state.get("weather", {})
        if int(current.get("day", -1)) == day and int(current.get("slot", -1)) == slot:
            return current
        rng = random.Random(day * 1009 + slot * 131 + 17)
        roll = rng.random()
        candidates: list[tuple[float, dict[str, Any]]] = [
            (0.58, {"kind": "sunny", "label": "晴天", "intensity": 0.1}),
            (0.12, {"kind": "breezy", "label": "晴朗有风", "intensity": 0.18}),
            (0.12, {"kind": "cloudy", "label": "多云", "intensity": 0.24}),
            (0.08, {"kind": "overcast", "label": "阴天", "intensity": 0.34}),
            (0.06, {"kind": "rain", "label": "下雨", "intensity": 0.7}),
            (0.02, {"kind": "snow", "label": "下雪", "intensity": 0.62}),
            (0.02, {"kind": "dust", "label": "沙尘", "intensity": 0.76}),
        ]
        selected = candidates[0][1]
        cursor = 0.0
        for weight, entry in candidates:
            cursor += weight
            if roll <= cursor:
                selected = entry
                break
        weather = dict(selected)
        weather["slot"] = slot
        weather["day"] = day
        previous_kind = str(current.get("kind", ""))
        self.state["weather"] = weather
        if previous_kind and previous_kind != str(weather["kind"]):
            self.state["global_news"].insert(
                0,
                {
                    "title": "天气换了一阵风向",
                    "body": f"城里天气转成{weather['label']}，摊位、人流和市场情绪都在跟着变。",
                    "tags": ["天气", str(weather["label"])],
                    "scope": "city",
                },
            )
            self.state["global_news"] = self.state["global_news"][:8]
        return weather

    def _apply_npc_schedule(self) -> None:
        minutes = int(self.state.get("clock_minutes", 8 * 60))
        period = str(self.state.get("time_period", "day"))
        for npc in self.state["npcs"]:
            work_anchor = {"x": float(npc.get("work_x", npc.get("x", 0.0))), "y": float(npc.get("work_y", npc.get("y", 0.0)))}
            home_anchor = {"x": float(npc.get("home_x", npc.get("x", 0.0))), "y": float(npc.get("home_y", npc.get("y", 0.0)))}
            depart_start, work_start, work_end, settle_home, sleep_start = self._schedule_window_for_npc(npc)
            target = work_anchor
            activity = "working"
            home_state = "away"
            if work_start <= minutes < work_end:
                target = self._schedule_patrol_anchor(npc, work_anchor, "work", minutes)
                activity = "working"
            elif depart_start <= minutes < work_start:
                ratio = (minutes - depart_start) / max(work_start - depart_start, 1)
                target = {
                    "x": home_anchor["x"] + (work_anchor["x"] - home_anchor["x"]) * ratio,
                    "y": home_anchor["y"] + (work_anchor["y"] - home_anchor["y"]) * ratio,
                }
                activity = "commuting"
            elif work_end <= minutes < settle_home:
                ratio = (minutes - work_end) / max(settle_home - work_end, 1)
                target = {
                    "x": work_anchor["x"] + (home_anchor["x"] - work_anchor["x"]) * ratio,
                    "y": work_anchor["y"] + (home_anchor["y"] - work_anchor["y"]) * ratio,
                }
                activity = "returning"
            else:
                target = self._schedule_patrol_anchor(npc, home_anchor, "home", minutes)
                activity = "home"
                if minutes >= sleep_start or minutes < max(depart_start - 40, 0):
                    home_state = "sleeping"
                elif settle_home <= minutes < sleep_start:
                    home_state = "evening_home"
                else:
                    home_state = "resting"
            route_x, route_y = self._activity_route_offset(npc, minutes, activity, home_state)
            npc["x"] = round(target["x"] + route_x, 1)
            npc["y"] = round(target["y"] + route_y, 1)
            npc["activity"] = activity
            npc["home_state"] = home_state
            npc["indoor_activity"] = self._indoor_activity_for_npc(npc, activity, home_state, minutes)
            npc["lights_on"] = activity == "home" and (period in {"dawn", "dusk", "night"} or home_state in {"sleeping", "evening_home"})
            carry_prop, carry_alpha = self._carry_state_for_npc(
                npc,
                activity,
                minutes,
                depart_start,
                work_start,
                work_end,
                settle_home,
            )
            npc["carry_prop"] = carry_prop
            npc["carry_alpha"] = carry_alpha
            npc["schedule_note"] = self._schedule_note_for_npc(
                npc,
                activity,
                home_state,
                str(npc.get("indoor_activity", "away")),
                minutes,
            )
        for district in self.state["districts"]:
            district["traffic"] = self._traffic_for_district(district)

    def _schedule_patrol_anchor(
        self,
        npc: dict[str, Any],
        base_anchor: dict[str, float],
        mode: str,
        minutes: int,
    ) -> dict[str, float]:
        if mode == "home":
            route_points = HOUSE_PATROL_POINTS.get(str(npc.get("home_id", "")), [])
        else:
            route_points = SUBREGION_ROUTE_POINTS.get(str(npc.get("subregion_id", "")), [])
        if not route_points:
            return {"x": float(base_anchor["x"]), "y": float(base_anchor["y"])}
        try:
            index_seed = max(1, int(str(npc.get("id", "npc_1")).split("_")[-1]))
        except ValueError:
            index_seed = (sum(ord(ch) for ch in str(npc.get("id", ""))) % 20) + 1
        cadence = 24 if mode == "home" else 18
        slot = int(minutes // cadence + index_seed) % len(route_points)
        next_slot = (slot + 1) % len(route_points)
        ratio = (minutes % cadence) / float(cadence)
        ax, ay = route_points[slot]
        bx, by = route_points[next_slot]
        mix = 0.18 + ratio * 0.64
        target_x = ax + (bx - ax) * mix
        target_y = ay + (by - ay) * mix
        return {
            "x": round((target_x + float(base_anchor["x"]) * 0.35) / 1.35, 1),
            "y": round((target_y + float(base_anchor["y"]) * 0.35) / 1.35, 1),
        }

    def _traffic_for_district(self, district: dict[str, Any]) -> int:
        minutes = int(self.state.get("clock_minutes", 8 * 60))
        base = int(district.get("traffic", 55))
        if minutes >= 20 * 60 or minutes < 6 * 60:
            return max(18, base - 28)
        if minutes < 8 * 60:
            return max(26, base - 12)
        if minutes < 17 * 60:
            return min(92, base + 4)
        return max(24, base - 6)

    def _derive_home_anchor(self, npc: dict[str, Any], index: int) -> tuple[float, float]:
        work_x = float(npc.get("x", 0.0))
        work_y = float(npc.get("y", 0.0))
        if work_x < 800 and work_y < 500:
            return 120.0 + (index % 5) * 118.0, 160.0 + (index % 3) * 54.0
        if work_x >= 800 and work_y < 500:
            return 940.0 + (index % 4) * 130.0, 182.0 + (index % 3) * 48.0
        if work_x < 800 and work_y >= 500:
            return 118.0 + (index % 4) * 126.0, 596.0 + (index % 4) * 56.0
        return 936.0 + (index % 5) * 102.0, 622.0 + (index % 3) * 64.0

    def _schedule_role_for_npc(self, npc: dict[str, Any]) -> str:
        role = str(npc.get("role", ""))
        if role in {"记者", "投机者", "银行经理"}:
            return "roamer"
        if role in {"店主", "老板", "代理人"}:
            return "keeper"
        return "worker"

    def _derive_home_anchor(self, npc: dict[str, Any], index: int) -> tuple[float, float]:
        offsets = {
            "slum_house": [(-16.0, 28.0), (16.0, 30.0), (-34.0, 60.0), (28.0, 58.0), (48.0, 10.0)],
            "dock_house": [(-18.0, 20.0), (18.0, 22.0), (-32.0, 48.0), (34.0, 50.0), (8.0, -12.0)],
            "factory_house": [(-22.0, 16.0), (18.0, 18.0), (-36.0, 44.0), (34.0, 46.0), (6.0, -10.0)],
            "exchange_house": [(-18.0, 22.0), (18.0, 22.0), (-34.0, 48.0), (34.0, 46.0), (4.0, -12.0)],
        }
        anchors = {
            "slum_house": (610.0, 560.0),
            "dock_house": (860.0, 720.0),
            "factory_house": (2240.0, 1120.0),
            "exchange_house": (1370.0, 610.0),
        }
        home_id = str(npc.get("home_id", "slum_house"))
        base_x, base_y = anchors.get(home_id, anchors["slum_house"])
        home_offsets = offsets.get(home_id, offsets["slum_house"])
        offset_x, offset_y = home_offsets[max(index, 0) % len(home_offsets)]
        return base_x + offset_x, base_y + offset_y

    def _house_for_district(self, district_name: str) -> dict[str, str]:
        return copy.deepcopy(HOUSE_DEFS.get(district_name, HOUSE_DEFS["贫民街"]))

    def _schedule_window_for_npc(self, npc: dict[str, Any]) -> tuple[int, int, int, int, int]:
        role = str(npc.get("schedule_role", "worker"))
        if role == "keeper":
            return 6 * 60 + 20, 7 * 60 + 30, 18 * 60, 19 * 60 + 5, 22 * 60
        if role == "roamer":
            return 7 * 60, 8 * 60 + 30, 18 * 60 + 30, 20 * 60 + 15, 22 * 60 + 30
        return 6 * 60, 8 * 60, 17 * 60, 19 * 60 + 20, 21 * 60 + 30

    def _activity_route_offset(self, npc: dict[str, Any], minutes: int, activity: str, home_state: str) -> tuple[float, float]:
        raw_id = str(npc.get("id", "npc_0")).split("_")[-1]
        try:
            index = max(1, int(raw_id))
        except ValueError:
            index = max(1, (sum(ord(ch) for ch in str(npc.get("id", ""))) % 19) + 1)
        role = str(npc.get("schedule_role", "worker"))
        district = str(npc.get("district", ""))
        subregion = str(npc.get("subregion_id", ""))
        sub_seed = (sum(ord(ch) for ch in subregion) % 23) / 23.0
        phase = minutes / 18.0 + index * 0.71 + sub_seed * 2.6
        route_step = int(minutes // (16 if role == "roamer" else 22 if role == "keeper" else 18) + index) % 5
        route_points = [
            (-1.0, -0.25),
            (-0.45, 0.82),
            (0.72, 0.58),
            (0.94, -0.42),
            (0.08, -0.9),
        ]
        turn_x, turn_y = route_points[route_step]
        drift_x = math.sin(phase) * 0.34 + math.cos(phase * 0.47) * 0.18
        drift_y = math.cos(phase * 1.13) * 0.28 + math.sin(phase * 0.63) * 0.14
        if district == "港口":
            drift_y *= 0.62
            drift_x += 0.08
        elif district == "交易所":
            drift_x *= 0.76
            drift_y -= 0.06
        elif district == "工厂区":
            drift_y += 0.1
        else:
            drift_x -= 0.06
        if activity == "working":
            radius_x, radius_y = 18.0, 10.0
            if role == "roamer":
                radius_x, radius_y = 34.0, 18.0
            elif role == "keeper":
                radius_x, radius_y = 14.0, 8.0
        elif activity in {"commuting", "returning"}:
            radius_x, radius_y = 12.0, 6.0
            turn_x *= 0.55
            turn_y *= 0.45
        else:
            if home_state == "sleeping":
                return round(math.sin(phase * 0.45) * 0.9, 1), round(math.cos(phase * 0.35) * 0.7, 1)
            radius_x, radius_y = (8.0, 4.0) if home_state == "resting" else (14.0, 8.0)
        return round((turn_x + drift_x) * radius_x, 1), round((turn_y + drift_y) * radius_y, 1)

    def _indoor_activity_for_npc(self, npc: dict[str, Any], activity: str, home_state: str, minutes: int) -> str:
        if activity != "home":
            return "away"
        if home_state == "sleeping":
            return "sleeping"
        role = str(npc.get("role", ""))
        district = str(npc.get("district", ""))
        npc_seed = int(str(npc.get("id", "npc_0")).split("_")[-1])
        is_early_evening = home_state == "evening_home"
        if role in {"记者", "银行经理"}:
            return "ledger" if is_early_evening else "reading"
        if role in {"代理人", "投机者"}:
            return "ledger" if minutes < 22 * 60 else "reading"
        if role in {"店主", "老板"}:
            return "sorting_goods" if is_early_evening else "ledger"
        if district == "港口":
            return "cooking" if is_early_evening else ("mending" if npc_seed % 2 == 0 else "eating")
        if district == "工厂区":
            return "washing" if is_early_evening else ("mending" if npc_seed % 2 == 0 else "warming")
        if district == "交易所":
            return "ledger" if is_early_evening else ("reading" if npc_seed % 2 == 0 else "eating")
        if minutes < 6 * 60 + 20:
            return "warming"
        return "cooking" if is_early_evening else ("sorting_goods" if npc_seed % 2 == 0 else "mending")

    def _carry_state_for_npc(
        self,
        npc: dict[str, Any],
        activity: str,
        minutes: int,
        depart_start: int,
        work_start: int,
        work_end: int,
        settle_home: int,
    ) -> tuple[str, float]:
        if activity == "commuting":
            commute_span = max(work_start - depart_start, 1)
            progress = (minutes - depart_start) / commute_span
            alpha = max(0.18, min(1.0, 1.08 - progress * 0.78))
            return self._morning_carry_prop(npc), round(alpha, 3)
        if activity == "returning":
            return_span = max(settle_home - work_end, 1)
            progress = (minutes - work_end) / return_span
            alpha = max(0.14, min(0.62, 0.58 - progress * 0.34))
            return self._evening_carry_prop(npc), round(alpha, 3)
        return "", 0.0

    def _morning_carry_prop(self, npc: dict[str, Any]) -> str:
        role = str(npc.get("role", ""))
        district = str(npc.get("district", ""))
        home_class = str(npc.get("home_class", ""))
        if role in {"记者", "银行经理"}:
            return "ledger"
        if role in {"工人", "工会领袖"} or district == "工厂区":
            return "tool"
        if role in {"代理人", "店主"} or district == "交易所":
            return "ledger"
        if district == "港口":
            return "satchel"
        if home_class in {"merchant", "upper"}:
            return "ledger"
        return "breakfast"

    def _evening_carry_prop(self, npc: dict[str, Any]) -> str:
        district = str(npc.get("district", ""))
        if district == "工厂区":
            return "tool"
        if district == "交易所":
            return "ledger"
        return "satchel"

    def _schedule_note_for_npc(
        self,
        npc: dict[str, Any],
        activity: str,
        home_state: str,
        indoor_activity: str,
        minutes: int,
    ) -> str:
        house_title = str(npc.get("home_label", "屋里"))
        if activity == "working":
            return f"{npc['name']} 白天还在 {npc['district']} 忙活。"
        if activity == "commuting":
            return f"{npc['name']} 正从 {house_title} 往工位赶。"
        if activity == "returning":
            return f"{npc['name']} 正往 {house_title} 收工回去。"
        if home_state == "sleeping":
            return f"{house_title} 的灯压暗了，{npc['name']} 已经歇下。"
        if indoor_activity == "cooking":
            return f"{npc['name']} 刚回到 {house_title}，正把锅重新热上。"
        if indoor_activity == "ledger":
            return f"{npc['name']} 在 {house_title} 的灯下翻账和记价。"
        if indoor_activity == "sorting_goods":
            return f"{npc['name']} 在 {house_title} 里翻箱清点剩货。"
        if indoor_activity == "washing":
            return f"{npc['name']} 回家先在 {house_title} 里洗灰和煤味。"
        if indoor_activity == "mending":
            return f"{npc['name']} 在 {house_title} 里补衣修工具，手还没停。"
        if indoor_activity == "reading":
            return f"{npc['name']} 在 {house_title} 里借着烛光翻纸页。"
        if indoor_activity == "eating":
            return f"{npc['name']} 端着热汤坐回了 {house_title}。"
        if home_state == "evening_home":
            return f"{npc['name']} 刚回到 {house_title}，灶火和灯还亮着。"
        if minutes < 6 * 60 + 20:
            return f"{npc['name']} 还在 {house_title} 里赖着不肯出门。"
        return f"{npc['name']} 正在 {house_title} 里歇脚整理东西。"

    def _build_house_states(self) -> dict[str, Any]:
        house_states: dict[str, Any] = {}
        priority = {"sleeping": 4, "evening_home": 3, "resting": 2, "away": 1}
        activity_priority = {
            "sleeping": 8,
            "ledger": 7,
            "cooking": 6,
            "sorting_goods": 5,
            "washing": 5,
            "mending": 4,
            "reading": 3,
            "eating": 3,
            "warming": 2,
            "away": 0,
        }
        for district_name, meta in HOUSE_DEFS.items():
            house_states[meta["id"]] = {
                "id": meta["id"],
                "title": meta["title"],
                "district": district_name,
                "household_class": meta["class"],
                "scene_id": meta.get("scene_id", ""),
                "entry_spawn_id": meta.get("entry_spawn_id", ""),
                "scene_anchor": {
                    "x": round(float(meta.get("anchor_x", 0.0)), 1),
                    "y": round(float(meta.get("anchor_y", 0.0)), 1),
                },
                "resident_count": 0,
                "residents_home": 0,
                "sleeping_count": 0,
                "lights_on": False,
                "primary_state": "away",
                "primary_resident": "",
                "primary_activity": "away",
                "secondary_activity": "away",
                "schedule_note": "白天屋里还空着。",
                "resident_names": [],
                "activity_mix": {},
                "summary_line": "",
                "commuting_count": 0,
                "window_glow_boost": 0.0,
                "residual_warmth": 0.0,
                "breakfast_leftovers": 0.0,
                "doorstep_alpha": 0.0,
                "doorstep_note": "",
                "doorstep_prop": "",
                "window_curve": "plain",
                "commuting_props": {},
            }
        minutes = int(self.state.get("clock_minutes", 8 * 60))
        period = str(self.state.get("time_period", "day"))
        for npc in self.state["npcs"]:
            home_id = str(npc.get("home_id", ""))
            if not home_id or home_id not in house_states:
                continue
            house_state = house_states[home_id]
            house_state["resident_count"] += 1
            house_state["resident_names"].append(str(npc.get("name", "")))
            if npc.get("activity") == "commuting":
                house_state["commuting_count"] += 1
                carry_prop = str(npc.get("carry_prop", ""))
                if carry_prop:
                    commute_props = house_state.get("commuting_props", {})
                    commute_props[carry_prop] = int(commute_props.get(carry_prop, 0)) + 1
                    house_state["commuting_props"] = commute_props
            if npc.get("activity") == "home":
                house_state["residents_home"] += 1
                activity_name = str(npc.get("indoor_activity", "away"))
                house_state["activity_mix"][activity_name] = int(house_state["activity_mix"].get(activity_name, 0)) + 1
                if npc.get("home_state") == "sleeping":
                    house_state["sleeping_count"] += 1
            house_state["lights_on"] = bool(house_state["lights_on"] or npc.get("lights_on", False))
            current_priority = priority.get(str(npc.get("home_state", "away")), 0)
            existing_priority = priority.get(str(house_state.get("primary_state", "away")), 0)
            current_activity = str(npc.get("indoor_activity", "away"))
            existing_activity = str(house_state.get("primary_activity", "away"))
            if current_priority > existing_priority or (
                current_priority == existing_priority
                and activity_priority.get(current_activity, 0) >= activity_priority.get(existing_activity, 0)
            ):
                house_state["primary_state"] = str(npc.get("home_state", "away"))
                house_state["primary_resident"] = str(npc.get("name", ""))
                house_state["primary_activity"] = current_activity
                house_state["schedule_note"] = str(npc.get("schedule_note", house_state["schedule_note"]))
        for house_state in house_states.values():
            house_state["resident_names"] = house_state["resident_names"][:4]
            activity_mix = {
                name: count
                for name, count in house_state.get("activity_mix", {}).items()
                if name != str(house_state.get("primary_activity", "away"))
            }
            if activity_mix:
                house_state["secondary_activity"] = max(activity_mix, key=activity_mix.get)
            self._decorate_house_transition_state(house_state, minutes, period)
            house_state["summary_line"] = self._compose_house_summary(house_state)
            house_state.pop("activity_mix", None)
            house_state.pop("commuting_props", None)
        return house_states

    def _decorate_house_transition_state(self, house_state: dict[str, Any], minutes: int, period: str) -> None:
        commuting_count = int(house_state.get("commuting_count", 0))
        residents_home = int(house_state.get("residents_home", 0))
        house_id = str(house_state.get("id", "slum_house"))
        curve_profiles = {
            "slum_house": {"start": 6 * 60 + 2, "end": 7 * 60 + 26, "power": 1.4, "curve": "warm_fast"},
            "dock_house": {"start": 6 * 60 + 8, "end": 7 * 60 + 56, "power": 0.88, "curve": "mist_long"},
            "factory_house": {"start": 5 * 60 + 58, "end": 7 * 60 + 44, "power": 1.12, "curve": "ember_pulse"},
            "exchange_house": {"start": 6 * 60 + 18, "end": 8 * 60 + 18, "power": 0.72, "curve": "gold_linger"},
        }
        profile = curve_profiles.get(house_id, curve_profiles["slum_house"])
        start_minutes = int(profile["start"])
        end_minutes = int(profile["end"])
        decay_progress = 0.0
        if minutes > start_minutes:
            decay_progress = max(0.0, min(1.0, (minutes - start_minutes) / max(end_minutes - start_minutes, 1)))
        morning_window = max(0.0, min(1.0, pow(1.0 - decay_progress, float(profile["power"]))))
        doorstep_alpha = 0.0
        if period in {"dawn", "day"}:
            if commuting_count > 0:
                doorstep_alpha = 0.42 + min(0.42, commuting_count * 0.18)
            elif residents_home <= 0 and minutes < 8 * 60 + 40:
                doorstep_alpha = 0.22
            doorstep_alpha *= morning_window
        window_boost = 0.0
        if bool(house_state.get("lights_on", False)):
            window_boost = 0.16
        if doorstep_alpha > 0.0:
            window_boost = max(window_boost, 0.08 + doorstep_alpha * 0.34)
        residual_warmth = 0.0
        breakfast_leftovers = 0.0
        primary_activity = str(house_state.get("primary_activity", "away"))
        if primary_activity in {"cooking", "warming", "eating"}:
            residual_warmth = 0.62
            breakfast_leftovers = 0.56
        elif doorstep_alpha > 0.0:
            residual_warmth = 0.28 + doorstep_alpha * 0.34
            breakfast_leftovers = 0.18 + doorstep_alpha * 0.36
        elif period == "dawn" and residents_home <= 0:
            residual_warmth = 0.26
            breakfast_leftovers = 0.22
        house_state["window_glow_boost"] = round(min(window_boost, 0.52), 3)
        house_state["residual_warmth"] = round(min(residual_warmth, 0.82), 3)
        house_state["breakfast_leftovers"] = round(min(breakfast_leftovers, 0.78), 3)
        house_state["doorstep_alpha"] = round(min(doorstep_alpha, 0.84), 3)
        house_state["window_curve"] = str(profile.get("curve", "plain"))
        commute_props = house_state.get("commuting_props", {})
        if commute_props:
            house_state["doorstep_prop"] = max(commute_props, key=commute_props.get)
        elif primary_activity in {"ledger", "reading"}:
            house_state["doorstep_prop"] = "ledger"
        elif primary_activity in {"sorting_goods", "mending"}:
            house_state["doorstep_prop"] = "satchel"
        elif primary_activity in {"cooking", "eating", "warming"}:
            house_state["doorstep_prop"] = "breakfast"
        else:
            house_state["doorstep_prop"] = ""
        if doorstep_alpha > 0.06:
            house_state["doorstep_note"] = "门槛边还带着刚离屋的脚步、晨光和余热。"
        elif residual_warmth > 0.2:
            house_state["doorstep_note"] = "门边安静下来后，屋里还留着刚热过锅的温度。"
        else:
            house_state["doorstep_note"] = ""

    def _compose_house_summary(self, house_state: dict[str, Any]) -> str:
        resident = str(house_state.get("primary_resident", "住户"))
        residents_home = int(house_state.get("residents_home", 0))
        sleeping_count = int(house_state.get("sleeping_count", 0))
        activity_name = str(house_state.get("primary_activity", "away"))
        if residents_home <= 0:
            return f"{house_state['title']} 白天多半空着，只剩些锅气和旧木头味。"
        if sleeping_count > 0:
            return f"{house_state['title']} 的床铺已经压出弧度，{resident} 正在里头歇着。"
        if activity_name == "cooking":
            return f"{house_state['title']} 的锅还在冒气，{resident} 正把晚饭重新热上。"
        if activity_name == "ledger":
            return f"{house_state['title']} 的灯下摊着账页，{resident} 还在慢慢对数。"
        if activity_name == "sorting_goods":
            return f"{house_state['title']} 的箱柜还敞着，{resident} 正在清点余粮和旧货。"
        if activity_name == "washing":
            return f"{house_state['title']} 的洗盆边还有水声，{resident} 正把灰尘和汗味洗掉。"
        if activity_name == "mending":
            return f"{house_state['title']} 床边摊着针线和工具，{resident} 还在补衣修物。"
        if activity_name == "reading":
            return f"{house_state['title']} 的烛光压着纸页，{resident} 正靠桌翻看消息。"
        if activity_name == "eating":
            return f"{house_state['title']} 桌边还摆着热汤和碗勺，{resident} 正在慢慢垫肚子。"
        if house_state.get("lights_on"):
            return f"{house_state['title']} 的灯亮着，{resident} 刚回家，屋里有人声和锅火。"
        return f"{house_state['title']} 里正有人停留，桌上账本和器具都还没收。"

    def _clock_label(self) -> str:
        minutes = int(self.state.get("clock_minutes", 8 * 60))
        hours = minutes // 60
        mins = minutes % 60
        return f"{hours:02d}:{mins:02d}"

    def _bootstrap_family(self, family: dict[str, Any]) -> None:
        total_holdings = sum(int(value) for value in family.get("stock_holdings", {}).values())
        family["asset_scale"] = round(float(family.get("asset_scale", (int(family.get("cash", 0)) + int(family.get("real_estate_holdings", 0)) * 12 + total_holdings * 8) / 100.0)), 2)
        family["risk_appetite"] = round(float(family.get("risk_appetite", 0.35 + min(0.45, int(family.get("debt", 0)) / 220.0))), 3)
        family["liquidity_preference"] = round(float(family.get("liquidity_preference", 0.45 + int(family.get("cash", 0)) / 600.0)), 3)
        family["political_power"] = int(family.get("political_power", 40))
        family["media_power"] = int(family.get("media_power", 20))
        family["primary_industries"] = list(family.get("primary_industries", [str(family.get("type", ""))]))
        family["public_strategy"] = str(family.get("public_strategy", family.get("public_action", family.get("strategy", "观望"))))
        family["shadow_strategy"] = str(family.get("shadow_strategy", family.get("hidden_action", "沿着街头放风")))

    def _bootstrap_company(self, company: dict[str, Any]) -> None:
        company["capacity"] = int(company.get("capacity", 60))
        company["inventory"] = int(company.get("inventory", max(20, int(company["capacity"] * 0.7))))
        company["workers"] = int(company.get("workers", 18))
        company["wage_level"] = int(company.get("wage_level", 6))
        company["accident_risk"] = float(company.get("accident_risk", 0.08))
        company["financing_pressure"] = float(company.get("financing_pressure", 45.0))
        company["order_pressure"] = float(company.get("order_pressure", 50.0))
        company["profit_margin"] = float(company.get("profit_margin", 0.12))
        company["media_sensitivity"] = float(company.get("media_sensitivity", 0.4))
        company["transport_dependency"] = float(company.get("transport_dependency", 0.3))
        company["operating_state"] = str(company.get("operating_state", "steady"))
        company["inventory_state"] = str(company.get("inventory_state", "balanced"))
        company["wage_pressure"] = float(company.get("wage_pressure", 35.0))
        company["payroll_delay"] = float(company.get("payroll_delay", max(4.0, company["financing_pressure"] * 0.22)))
        company["credit_line"] = float(company.get("credit_line", max(18.0, 92.0 - company["financing_pressure"])))

    def _bootstrap_npc(self, npc: dict[str, Any], companies: list[dict[str, Any]]) -> None:
        npc["cash"] = int(npc.get("cash", npc.get("money", 0)))
        npc["debt"] = int(npc.get("debt", max(0, 18 - int(npc.get("cash", npc.get("money", 0))))))
        npc["inventory"] = copy.deepcopy(npc.get("inventory", {"面包": 0, "煤": 0, "罐头": 0}))
        npc["reputation"] = int(npc.get("reputation", 18 + int(npc.get("player_relation", 0))))
        npc["player_trust"] = float(npc.get("player_trust", max(0, 42 + int(npc.get("player_relation", 0)) * 4)))
        npc["anxiety"] = float(npc.get("anxiety", npc.get("fear", 0)))
        npc["greed_drive"] = float(npc.get("greed_drive", npc.get("greed", 0)))
        npc["current_target"] = str(npc.get("current_target", npc.get("current_goal", npc.get("district", ""))))
        npc["heard_topic_ids"] = list(npc.get("heard_topic_ids", []))
        npc["last_trade_pnl"] = float(npc.get("last_trade_pnl", 0.0))
        npc["job_security"] = float(npc.get("job_security", max(18.0, 76.0 - npc["debt"] * 0.8)))
        npc["income_type"] = str(npc.get("income_type", self._default_income_type(npc)))
        npc["housing_cost"] = int(npc.get("housing_cost", self._default_housing_cost(npc)))
        npc["rumor_sensitivity"] = float(npc.get("rumor_sensitivity", npc.get("rumor_susceptibility", 0.4)))
        npc["info_reliability"] = float(npc.get("info_reliability", max(0.18, 0.82 - float(npc.get("rumor_susceptibility", 0.4)) * 0.45)))
        npc["moral_floor"] = float(npc.get("moral_floor", max(0.08, 0.72 - float(npc.get("risk_preference", 40)) / 120.0)))
        npc["political_stance"] = str(npc.get("political_stance", "self_preservation"))
        npc["consumption_profile"] = str(npc.get("consumption_profile", "subsistence" if npc.get("class") == "底层" else "status"))
        npc["company_id"] = str(npc.get("company_id", self._infer_company_id_for_npc(npc, companies)))
        npc["information_domain"] = self._npc_information_domains(npc)
        npc["stock_positions"] = copy.deepcopy(npc.get("stock_positions", self._default_stock_positions(npc)))
        npc["goods_positions"] = copy.deepcopy(npc.get("goods_positions", self._default_goods_positions(npc)))
        npc["relationship_memory"] = copy.deepcopy(npc.get("relationship_memory", []))
        npc["player_memory"] = copy.deepcopy(
            npc.get(
                "player_memory",
                {
                    "talk_count": 0,
                    "friendly_count": 0,
                    "hardball_count": 0,
                    "intel_bought": 0,
                    "pressure_from_player": 0.0,
                    "trust_streak": 0,
                    "last_topic_id": "",
                    "last_intent": "",
                    "last_approach": "",
                    "last_seen_day": 1,
                },
            )
        )
        npc["agent_prompt"] = self._npc_agent_prompt(npc)
        npc["agent_tool_policy"] = self._npc_tool_policy(npc)
        npc["agent_memory"] = copy.deepcopy(npc.get("agent_memory", []))
        npc["agent_queue"] = copy.deepcopy(npc.get("agent_queue", []))
        npc["agent_budget"] = copy.deepcopy(
            npc.get(
                "agent_budget",
                {
                    "daily_calls": self._npc_daily_agent_budget(npc),
                    "calls_left": self._npc_daily_agent_budget(npc),
                    "last_day": 1,
                    "last_reason": "",
                },
            )
        )
        npc["agent_policy"] = {
            "cadence": int(npc.get("llm_refresh_cadence", 1)),
            "tool_mode": "observe_only",
            "allow_market_spin": True,
            "allow_news_hint": True,
            "social_style": self._npc_social_style(npc),
            "market_style": self._npc_market_style(npc),
            "agenda": self._npc_agent_agenda(npc),
            "budget_weight": round(max(0.4, min(1.8, self._npc_daily_agent_budget(npc) / 6.0)), 2),
        }
        npc["proactive_interest"] = float(
            npc.get(
                "proactive_interest",
                max(0.24, min(0.92, 0.28 + float(npc.get("player_relation", 0)) * 0.06 + float(npc.get("social_radius", 160)) / 520.0)),
            )
        )
        npc["proactive_cooldown_until"] = float(npc.get("proactive_cooldown_until", 0.0))

    def _default_income_type(self, npc: dict[str, Any]) -> str:
        role = str(npc.get("role", ""))
        if role in {"工人", "临时工", "工会领袖"}:
            return "wage"
        if role in {"店主", "老板"}:
            return "business"
        if role in {"记者", "代理人", "银行经理"}:
            return "commission"
        if role in {"投机者"}:
            return "speculation"
        return "odd_jobs"

    def _default_housing_cost(self, npc: dict[str, Any]) -> int:
        class_name = str(npc.get("class", ""))
        if class_name == "关键角色":
            return 8
        if class_name == "中层":
            return 6
        return 3

    def _npc_daily_agent_budget(self, npc: dict[str, Any]) -> int:
        role = str(npc.get("role", ""))
        if role in {"记者", "代理人", "银行经理"}:
            return 8
        if role in {"工会领袖", "投机者", "老板"}:
            return 7
        if role in {"店主"}:
            return 6
        return 5

    def _npc_tool_policy(self, npc: dict[str, Any]) -> list[str]:
        policy = ["只观察截图与状态", "不篡改规则层事实", "不直接改价格", "不输出思维过程", "必须只说中文"]
        role = str(npc.get("role", ""))
        district = str(npc.get("district", ""))
        family = str(npc.get("family_affiliation", "")) or "无"
        if role in {"记者", "代理人"}:
            policy.append("优先包装传闻与舆论")
        if role in {"工人", "临时工", "工会领袖"}:
            policy.append("优先关心工钱、班次、口粮和住房")
        if role in {"投机者", "银行经理"}:
            policy.append("优先关心利率、信用、仓位和抛压")
        if role in {"老板", "店主"}:
            policy.append("优先保护现金流、库存和客流")
        if family != "无":
            policy.append(f"优先维护{family}的表面利益")
        if district == "交易所":
            policy.append("默认从资金和价格角度理解事件")
        elif district == "工厂区":
            policy.append("默认从工钱、裁员和罢工角度理解事件")
        elif district == "港口":
            policy.append("默认从货流、班次和装卸风险角度理解事件")
        else:
            policy.append("默认从房租、粮价和街头口碑角度理解事件")
        return policy

    def _npc_social_style(self, npc: dict[str, Any]) -> str:
        role = str(npc.get("role", ""))
        if role in {"记者", "代理人"}:
            return "主动探口风，擅长递话、试探和二次传播"
        if role == "工会领袖":
            return "会主动把零散抱怨拢成集体情绪"
        if role in {"投机者", "银行经理"}:
            return "偏冷静，先看筹码，再决定要不要说真话"
        if role in {"老板", "店主"}:
            return "先算账，再说话，倾向维护自己的地盘"
        if role in {"工人", "临时工"}:
            return "更在意工钱、口粮和今天能不能熬过去"
        return "谨慎观望，只在有利时多说几句"

    def _npc_market_style(self, npc: dict[str, Any]) -> str:
        role = str(npc.get("role", ""))
        risk = float(npc.get("risk_preference", 40.0))
        if role == "投机者":
            return "追涨杀跌，喜欢把局部波动放大成行情"
        if role == "银行经理":
            return "关注信用收缩、利率和坏账，偏向控险"
        if role in {"代理人", "记者"}:
            return "通过风声和叙事影响盘口，而不是直接下场"
        if role in {"老板", "店主"}:
            return "优先保现金流和库存，涨太快也会担心接不住"
        if risk >= 65:
            return "敢赌，但也容易在高位变得敏感"
        return "偏保守，只在看见确定机会时跟进"

    def _npc_agent_agenda(self, npc: dict[str, Any]) -> str:
        role = str(npc.get("role", ""))
        goal = str(npc.get("current_goal", npc.get("current_target", "活下去")))
        family = str(npc.get("family_affiliation", "")) or "无家族"
        if role == "记者":
            return f"把能卖的真话和能点火的风声区分开，再挑最值钱的那条。当前目标：{goal}。"
        if role == "代理人":
            return f"替{family}试探情绪、放风和控场，但不能把牌直接打穿。当前目标：{goal}。"
        if role == "工会领袖":
            return f"判断街头不满值不值得组织起来，并寻找能带头的人。当前目标：{goal}。"
        if role in {"老板", "店主"}:
            return f"先守住现金流、货和人，再决定要不要冒险。当前目标：{goal}。"
        if role in {"投机者", "银行经理"}:
            return f"判断现在该追价、护盘还是先退一步，不能只会单边押注。当前目标：{goal}。"
        return f"优先保住今天的生计，再考虑明天要站哪边。当前目标：{goal}。"

    def _npc_agent_prompt(self, npc: dict[str, Any]) -> str:
        family = str(npc.get("family_affiliation", "")) or "无家族靠山"
        subregion = str(npc.get("subregion_name", "")) or str(npc.get("district", ""))
        domains = "、".join([str(value) for value in npc.get("information_domain", [])[:4]]) or "街头风声"
        social_style = self._npc_social_style(npc)
        market_style = self._npc_market_style(npc)
        agenda = self._npc_agent_agenda(npc)
        return (
            f"你是常驻 NPC agent：{npc.get('name', '无名者')}。"
            f"物种={npc.get('species', '动物')}，职业={npc.get('role', '街头角色')}，阶层={npc.get('class', '底层')}，"
            f"家族={family}，常驻区={npc.get('district', '街区')}，活动点={subregion}。"
            f"现金={int(npc.get('cash', 0))}，债务={int(npc.get('debt', 0))}，饥饿={int(npc.get('hunger', 0))}，"
            f"恐惧={int(npc.get('fear', 0))}，贪婪={int(npc.get('greed', 0))}，忠诚={int(npc.get('loyalty', 0))}。"
            f"说话口气={npc.get('voice_style', '平稳')}，关注领域={domains}。"
            f"社交风格={social_style}。金融风格={market_style}。"
            f"{agenda}"
            f"你必须按自己的利益、饥饿、债务、声望、忠诚和恐惧说话，不得替玩家或旁人做决定。"
            f"你会保留自己的记忆和立场，但不能凭空发明世界事实。"
        )

    def _npc_agent_profile(self, npc: dict[str, Any]) -> dict[str, Any]:
        budget = npc.get("agent_budget", {})
        return {
            "agent_id": str(npc.get("id", "")),
            "system_prompt": str(npc.get("agent_prompt", "")),
            "identity": {
                "name": str(npc.get("name", "")),
                "role": str(npc.get("role", "")),
                "family": str(npc.get("family_affiliation", "")) or "无",
                "district": str(npc.get("district", "")),
                "subregion": str(npc.get("subregion_name", "")) or str(npc.get("district", "")),
                "social_style": self._npc_social_style(npc),
                "market_style": self._npc_market_style(npc),
            },
            "tool_policy": copy.deepcopy(npc.get("agent_tool_policy", [])),
            "memory": copy.deepcopy(list(npc.get("agent_memory", []))[:6]),
            "queue": copy.deepcopy(list(npc.get("agent_queue", []))[:4]),
            "budget": {
                "daily_calls": int(budget.get("daily_calls", self._npc_daily_agent_budget(npc))),
                "calls_left": int(budget.get("calls_left", self._npc_daily_agent_budget(npc))),
                "last_day": int(budget.get("last_day", int(self.state.get("day", 1)))),
                "last_reason": str(budget.get("last_reason", "")),
            },
            "policy": copy.deepcopy(npc.get("agent_policy", {})),
        }

    def _refresh_agent_budget(self, npc: dict[str, Any]) -> None:
        budget = npc.get("agent_budget", {})
        if not isinstance(budget, dict):
            budget = {}
            npc["agent_budget"] = budget
        day = int(self.state.get("day", 1))
        if int(budget.get("last_day", day)) != day:
            daily_calls = self._npc_daily_agent_budget(npc)
            budget["daily_calls"] = daily_calls
            budget["calls_left"] = daily_calls
            budget["last_day"] = day
            budget["last_reason"] = "daily_reset"

    def _consume_agent_budget(self, npc: dict[str, Any], reason: str, cost: int = 1) -> bool:
        self._refresh_agent_budget(npc)
        budget = npc.get("agent_budget", {})
        calls_left = int(budget.get("calls_left", self._npc_daily_agent_budget(npc)))
        if calls_left < cost:
            return False
        budget["calls_left"] = calls_left - cost
        budget["last_reason"] = reason
        return True

    def _queue_agent_task(self, npc: dict[str, Any], kind: str, note: str) -> None:
        queue = npc.get("agent_queue", [])
        if not isinstance(queue, list):
            queue = []
        queue.insert(
            0,
            {
                "day": int(self.state.get("day", 1)),
                "clock": self._clock_label(),
                "kind": kind,
                "note": note[:96],
            },
        )
        npc["agent_queue"] = queue[:8]

    def _remember_agent_output(self, npc: dict[str, Any], kind: str, summary: str) -> None:
        rows = npc.get("agent_memory", [])
        if not isinstance(rows, list):
            rows = []
        rows.insert(
            0,
            {
                "day": int(self.state.get("day", 1)),
                "clock": self._clock_label(),
                "kind": kind,
                "summary": summary[:140],
            },
        )
        npc["agent_memory"] = rows[:12]

    @staticmethod
    def _is_english_heavy_text(text: str) -> bool:
        ascii_letters = sum(1 for ch in text if ("a" <= ch <= "z") or ("A" <= ch <= "Z"))
        cjk_chars = sum(1 for ch in text if "\u4e00" <= ch <= "\u9fff")
        return ascii_letters >= 10 and ascii_letters > cjk_chars * 2

    def _prefer_chinese_text(self, text: str, fallback: str) -> str:
        cleaned = str(text or "").strip()
        if not cleaned:
            return fallback
        if self._is_english_heavy_text(cleaned):
            return fallback
        return cleaned

    def _normalize_spoken_line(self, speaker_name: str, line: str, fallback: str = "") -> str:
        cleaned = str(line or "").strip()
        if not cleaned:
            return fallback
        prefixes = [
            f"{speaker_name}：",
            f"{speaker_name}:",
            f"{speaker_name} :",
            f"{speaker_name} ：",
        ]
        changed = True
        while changed:
            changed = False
            for prefix in prefixes:
                if cleaned.startswith(prefix):
                    cleaned = cleaned[len(prefix) :].strip()
                    changed = True
        return self._prefer_chinese_text(cleaned, fallback)

    def _infer_company_id_for_npc(self, npc: dict[str, Any], companies: list[dict[str, Any]]) -> str:
        role = str(npc.get("role", ""))
        district = str(npc.get("district", ""))
        for company in companies:
            if role in {"记者", "银行经理", "投机者"} and str(company.get("district", "")) == "交易所":
                return str(company.get("id", ""))
            if role in {"工人", "工会领袖"} and district == str(company.get("district", "")):
                return str(company.get("id", ""))
            if district == str(company.get("district", "")) and role in {"店主", "老板", "代理人"}:
                return str(company.get("id", ""))
        return ""

    def _npc_information_domains(self, npc: dict[str, Any]) -> list[str]:
        role = str(npc.get("role", ""))
        district = str(npc.get("district", ""))
        mapping = {
            "工人": ["labor", "ration", district],
            "临时工": ["labor", "street", district],
            "店主": ["trade", "credit", district],
            "老板": ["trade", "company", district],
            "记者": ["media", "family", district],
            "代理人": ["family", "stock", district],
            "投机者": ["stock", "rumor", district],
            "银行经理": ["credit", "interest", "family"],
            "工会领袖": ["labor", "unrest", district],
        }
        return [value for value in mapping.get(role, ["rumor", district]) if value]

    def _default_stock_positions(self, npc: dict[str, Any]) -> dict[str, int]:
        role = str(npc.get("role", ""))
        if role in {"投机者", "代理人", "银行经理"}:
            return {
                str(stock.get("name", "")): 1 if str(stock.get("family_owner", "")) == str(npc.get("family_affiliation", "")) else 0
                for stock in self.stock_defs
            }
        return {}

    def _default_goods_positions(self, npc: dict[str, Any]) -> dict[str, int]:
        district = str(npc.get("district", ""))
        if district == "贫民街":
            return {"面包": 1}
        if district == "工厂区":
            return {"煤": 1}
        if district == "港口":
            return {"罐头": 1}
        return {}

    def _run_livelihood_tick(self, phase: str) -> None:
        phase_scale = 1.0 if phase == "end_day" else 0.35
        for npc in self.state.get("npcs", []):
            company = self._find_by_id(self.state.get("companies", []), str(npc.get("company_id", "")))
            wage_level = float(company.get("wage_level", 5.0)) if company else 4.0
            job_security = float(npc.get("job_security", 50.0))
            payroll_drag = max(0.3, 1.0 - float(company.get("payroll_delay", 0.0)) / 150.0) if company else 1.0
            if str(npc.get("income_type", "")) == "wage":
                income = wage_level * phase_scale * max(0.45, min(1.2, job_security / 75.0)) * payroll_drag
            elif str(npc.get("income_type", "")) == "commission":
                income = (4.0 + float(self.state["macro"].get("media_sentiment", 50)) * 0.03) * phase_scale
            elif str(npc.get("income_type", "")) == "business":
                income = (5.0 + float(self.state["macro"].get("economy_heat", 50)) * 0.05) * phase_scale
            elif str(npc.get("income_type", "")) == "speculation":
                income = (3.0 + float(self.state["market_pressure"]["stocks"].get(next(iter(npc.get("stock_positions", {"": 0}))), 0.0)) * 20.0) * phase_scale
            else:
                income = 2.8 * phase_scale
            food_cost = (1.4 + float(npc.get("hunger", 40)) / 90.0) * phase_scale
            rent_cost = float(npc.get("housing_cost", 4)) * (1.0 if phase == "end_day" else 0.0)
            debt_cost = float(npc.get("debt", 0)) * (0.035 if phase == "end_day" else 0.01)
            cash = float(npc.get("cash", 0)) + income - food_cost - rent_cost - debt_cost
            debt = float(npc.get("debt", 0))
            if cash < 0:
                debt += abs(cash)
                cash = 0.0
            npc["cash"] = int(round(cash))
            npc["debt"] = int(round(min(180.0, debt)))
            pressure = max(0.0, min(1.4, (rent_cost + debt_cost + food_cost - income) / 10.0 + debt / 140.0))
            npc["anxiety"] = round(max(0.0, min(100.0, float(npc.get("anxiety", 0.0)) + pressure * 18.0 - income * 0.6)), 2)
            npc["greed_drive"] = round(max(0.0, min(100.0, float(npc.get("greed_drive", npc.get("greed", 0))) + max(0.0, income - food_cost) * 1.2)), 2)
            npc["job_security"] = round(max(10.0, min(100.0, job_security + income * 0.4 - pressure * 9.0)), 2)
            if company and float(company.get("payroll_delay", 0.0)) >= 34.0:
                npc["debt"] = min(180, int(npc.get("debt", 0)) + (1 if phase == "end_day" else 0))
                npc["memory_tags"] = self._push_memory(list(npc.get("memory_tags", [])), "late_pay")
                self._bump_district_signal(str(npc.get("district", "")), "fear", 0.03 * phase_scale)
            if pressure >= 0.55:
                npc["fear"] = min(100, int(npc.get("fear", 0)) + 4)
                self._bump_district_signal(str(npc.get("district", "")), "fear", 0.05 * phase_scale)
                self._bump_district_signal(str(npc.get("district", "")), "labor_heat", 0.04 * phase_scale)
            if float(npc.get("debt", 0)) > float(npc.get("housing_cost", 4)) * 4:
                npc["memory_tags"] = self._push_memory(list(npc.get("memory_tags", [])), "debt")
            if sum(int(value) for value in npc.get("stock_positions", {}).values()) > 0:
                self._bump_district_signal(str(npc.get("district", "")), "liquidity", 0.03 * phase_scale)

    def _settle_company_operations(self, phase: str) -> None:
        phase_scale = 1.0 if phase == "end_day" else 0.35
        for company in self.state.get("companies", []):
            district_name = str(company.get("district", ""))
            signals = self.state.get("district_signals", {}).get(district_name, {})
            labor_heat = float(signals.get("labor_heat", 0.0))
            fear = float(signals.get("fear", 0.0))
            liquidity = float(signals.get("liquidity", 0.0))
            trade_heat = float(signals.get("trade_heat", 0.0))
            company["order_pressure"] = max(12.0, min(100.0, float(company.get("order_pressure", 50.0)) + ((float(self.state["macro"].get("economy_heat", 50)) - 50.0) * 0.16 + trade_heat * 4.2 - fear * 2.4) * phase_scale))
            company["financing_pressure"] = max(8.0, min(100.0, float(company.get("financing_pressure", 45.0)) + ((float(self.state["macro"].get("interest_rate", 2.0)) - 2.0) * 6.5 + fear * 4.0 - liquidity * 2.5) * phase_scale))
            company["inventory"] = int(max(12.0, min(180.0, float(company.get("inventory", 60)) + (float(company.get("capacity", 60)) * 0.06 - company["order_pressure"] * 0.05 - fear * 1.8 + liquidity * 0.8) * phase_scale)))
            company["profit_margin"] = max(0.04, min(0.32, float(company.get("profit_margin", 0.12)) + ((company["order_pressure"] - 50.0) * 0.0014 - (company["financing_pressure"] - 45.0) * 0.0011 - float(company.get("accident_risk", 0.08)) * 0.04) * phase_scale))
            company["payroll_delay"] = max(0.0, min(100.0, float(company.get("payroll_delay", 0.0)) + ((company["financing_pressure"] - 48.0) * 0.08 + labor_heat * 2.8 - liquidity * 1.7) * phase_scale))
            company["credit_line"] = max(6.0, min(100.0, float(company.get("credit_line", 40.0)) + ((liquidity - fear) * 5.2 - float(company.get("financing_pressure", 45.0)) * 0.05) * phase_scale))

    def _rebuild_company_states(self) -> None:
        states: list[dict[str, Any]] = []
        company_briefings = self.state.get("company_briefings", {})
        for company in self.state.get("companies", []):
            linked_npcs = [npc for npc in self.state.get("npcs", []) if str(npc.get("company_id", "")) == str(company.get("id", ""))]
            if not linked_npcs:
                linked_npcs = [npc for npc in self.state.get("npcs", []) if str(npc.get("district", "")) == str(company.get("district", ""))]
            avg_anxiety = sum(float(npc.get("anxiety", npc.get("fear", 0))) for npc in linked_npcs) / max(1, len(linked_npcs))
            avg_job_security = sum(float(npc.get("job_security", 50.0)) for npc in linked_npcs) / max(1, len(linked_npcs))
            wage_pressure = max(10.0, min(100.0, float(self.state["macro"].get("worker_unrest", 50)) * 0.55 + avg_anxiety * 0.38 - float(company.get("wage_level", 6)) * 2.1))
            inventory_ratio = float(company.get("inventory", 1)) / max(1.0, float(company.get("capacity", 1)))
            payroll_delay = float(company.get("payroll_delay", 0.0))
            pressure_score = (wage_pressure + float(company.get("financing_pressure", 0.0)) + payroll_delay) / 3.0
            if wage_pressure >= 68 or float(company.get("financing_pressure", 0.0)) >= 72:
                operating_state = "strained"
            elif float(company.get("order_pressure", 0.0)) >= 65 and inventory_ratio < 0.9:
                operating_state = "expanding"
            else:
                operating_state = "steady"
            inventory_state = "tight" if inventory_ratio < 0.75 else "heavy" if inventory_ratio > 1.18 else "balanced"
            company["wage_pressure"] = round(wage_pressure, 2)
            company["operating_state"] = operating_state
            company["inventory_state"] = inventory_state
            funding_state = "dry" if float(company.get("credit_line", 40.0)) <= 18 else "tight" if float(company.get("financing_pressure", 0.0)) >= 62 else "open"
            workforce_mood = "resentful" if wage_pressure >= 66 or payroll_delay >= 32 else "rallying" if avg_job_security >= 62 and operating_state == "expanding" else "guarded"
            briefing = company_briefings.get(str(company.get("id", "")), {})
            recent_briefs = copy.deepcopy(self._entity_brief_history("company_brief_history", str(company.get("id", ""))))
            states.append(
                {
                    "id": str(company.get("id", "")),
                    "name": str(company.get("name", "")),
                    "district": str(company.get("district", "")),
                    "family_owner": str(company.get("family_owner", "")),
                    "stock_name": str(company.get("stock_name", "")),
                    "operating_state": operating_state,
                    "inventory_state": inventory_state,
                    "inventory": int(company.get("inventory", 0)),
                    "capacity": int(company.get("capacity", 0)),
                    "wage_pressure": round(wage_pressure, 2),
                    "payroll_delay": round(payroll_delay, 2),
                    "financing_pressure": round(float(company.get("financing_pressure", 0.0)), 2),
                    "order_pressure": round(float(company.get("order_pressure", 0.0)), 2),
                    "profit_margin": round(float(company.get("profit_margin", 0.0)), 3),
                    "credit_line": round(float(company.get("credit_line", 0.0)), 2),
                    "funding_state": funding_state,
                    "workforce_mood": workforce_mood,
                    "pressure_score": round(pressure_score, 2),
                    "active_move": str(company.get("active_move", "")),
                    "headline": str(briefing.get("headline", "")) or self._company_headline(company, operating_state, inventory_state),
                    "worker_note": str(briefing.get("worker_note", workforce_mood)),
                    "risk_note": str(briefing.get("risk_note", funding_state)),
                    "briefing_signal": str(briefing.get("signal", self._company_signal_from_state(company))),
                    "briefing_source": str(briefing.get("source", "rule")),
                    "recent_briefs": recent_briefs,
                    "brief_history_summary": self._brief_history_summary(recent_briefs, ("headline", "risk_note", "worker_note")),
                }
            )
        self.state["company_states"] = states

    def _company_headline(self, company: dict[str, Any], operating_state: str, inventory_state: str) -> str:
        if float(company.get("payroll_delay", 0.0)) >= 34.0:
            return f"{company.get('name', '公司')} 工钱开始拖，脸色比账本更先发紧。"
        if operating_state == "strained":
            return f"{company.get('name', '公司')} 账紧、人也紧。"
        if operating_state == "expanding":
            return f"{company.get('name', '公司')} 单子在涨，手脚已经不够用。"
        if inventory_state == "tight":
            return f"{company.get('name', '公司')} 库存发薄，谁都怕先断货。"
        return f"{company.get('name', '公司')} 还撑得住，但没人真觉得稳。"

    def _apply_institution_actions(self, trigger: str) -> None:
        self._rebuild_company_states()
        self._rebuild_family_moves()
        actions: list[dict[str, Any]] = []
        for company_state in list(self.state.get("company_states", [])):
            action = self._decide_company_action(company_state, trigger)
            if action:
                self._execute_company_action(action)
                actions.append(self._publish_institution_action(action))
        self._rebuild_company_states()
        self._rebuild_family_moves()
        for family_move in list(self.state.get("family_moves", [])):
            action = self._decide_family_action(family_move, trigger)
            if action:
                self._execute_family_action(action)
                actions.append(self._publish_institution_action(action))
        actions.sort(key=lambda item: float(item.get("weight", 0.0)), reverse=True)
        self.state["institution_actions"] = actions[:8]
        if self.state["institution_actions"] and not any(str(news.get("title", "")) == "几家机构先动了手" for news in self.state.get("global_news", [])[:2]):
            lead = self.state["institution_actions"][0]
            self.state["global_news"].insert(
                0,
                {
                    "title": "几家机构先动了手",
                    "body": str(lead.get("public_line", "")),
                    "tags": ["机构", str(lead.get("actor_type", "")), str(lead.get("district", ""))],
                    "scope": "city",
                    "tone": "cold",
                },
            )
            self.state["global_news"] = self.state["global_news"][:8]

    def _publish_institution_action(self, action: dict[str, Any]) -> dict[str, Any]:
        published = copy.deepcopy(action)
        score = round(max(0.18, min(0.98, float(action.get("weight", 0.0)) / 100.0)), 3)
        scope = "city" if score >= 0.72 or str(action.get("actor_type", "")) == "family" else "district"
        tags = ["机构", str(action.get("actor_type", "")), str(action.get("district", ""))]
        target_asset = str(action.get("target_asset", ""))
        if target_asset:
            tags.append(target_asset)
        news_copy = self.ark.generate_news_copy(
            {
                "event_name": f"{action.get('actor_name', '机构')} 的{self._institution_action_label(str(action.get('kind', '')))}",
                "district": str(action.get("district", "")),
                "macro": self.state.get("macro", {}),
                "stocks": [{row["name"]: row["current_price"]} for row in self.state.get("stocks", [])],
                "scene_observation": self.state.get("scene_observation", {}),
            }
        )
        if not news_copy:
            news_copy = {
                "title": self._institution_headline(action),
                "body": self._institution_news_body(action),
                "tags": tags,
                "tone": "cold",
            }
        published["scope"] = scope
        published["effect_score"] = score
        published["headline"] = str(news_copy.get("title", self._institution_headline(action)))
        published["news_body"] = str(news_copy.get("body", self._institution_news_body(action)))
        published["tags"] = list(news_copy.get("tags", tags))
        published["tone"] = str(news_copy.get("tone", "cold"))
        packet = {
            "source": str(action.get("actor_name", "机构")),
            "district": str(action.get("district", "")),
            "line": str(action.get("hidden_line", action.get("public_line", ""))),
            "title": published["headline"],
            "body": published["news_body"],
            "tags": published["tags"],
            "scope": scope,
            "goods_delta": {},
            "stocks_delta": {},
            "macro_delta": {},
            "family_delta": {},
        }
        self._apply_intel_packet(packet, to_player=False, promote_news=scope == "city", intensity=0.42 + score * 0.28)
        if scope != "city":
            self.state["global_news"].insert(
                0,
                {
                    "title": published["headline"],
                    "body": published["news_body"],
                    "tags": published["tags"],
                    "scope": "district",
                    "tone": published["tone"],
                },
            )
            self.state["global_news"] = self.state["global_news"][:8]
        return published

    def _institution_action_label(self, kind: str) -> str:
        mapping = {
            "bridge_loan": "过桥借钱",
            "cut_shift": "砍班次",
            "overtime_push": "抢单加班",
            "bury_story": "压消息",
            "spin_campaign": "舆论带风",
            "support_asset": "护盘",
            "lean_short": "压盘",
            "tighten_books": "收紧账本",
        }
        return mapping.get(kind, "动作")

    def _institution_headline(self, action: dict[str, Any]) -> str:
        actor_name = str(action.get("actor_name", "机构"))
        target_asset = str(action.get("target_asset", ""))
        kind = str(action.get("kind", ""))
        if kind == "bridge_loan":
            return f"{actor_name} 在找过桥钱"
        if kind == "cut_shift":
            return f"{actor_name} 开始砍班次"
        if kind == "overtime_push":
            return f"{actor_name} 连夜加班抢单"
        if kind == "bury_story":
            return f"{actor_name} 正在压消息"
        if kind == "spin_campaign":
            return f"{actor_name} 放风试温度"
        if kind == "support_asset":
            return f"{actor_name} 护着 {target_asset or '票面'}"
        if kind == "lean_short":
            return f"{actor_name} 在压 {target_asset or '盘面'}"
        if kind == "tighten_books":
            return f"{actor_name} 收紧账本"
        return f"{actor_name} 先动了手"

    def _institution_news_body(self, action: dict[str, Any]) -> str:
        public_line = str(action.get("public_line", ""))
        hidden_line = str(action.get("hidden_line", ""))
        district_name = str(action.get("district", "街区"))
        if hidden_line:
            return f"{public_line} 街面上的说法已经传进 {district_name}，但真正让人紧起来的是另一层意思：{hidden_line}"
        return public_line

    def _decide_company_action(self, company_state: dict[str, Any], trigger: str) -> dict[str, Any] | None:
        company = self._find_by_id(self.state.get("companies", []), str(company_state.get("id", "")))
        if not company:
            return None
        district_name = str(company_state.get("district", ""))
        stock_name = str(company_state.get("stock_name", ""))
        financing_pressure = float(company_state.get("financing_pressure", 0.0))
        wage_pressure = float(company_state.get("wage_pressure", 0.0))
        order_pressure = float(company_state.get("order_pressure", 0.0))
        inventory_state = str(company_state.get("inventory_state", "balanced"))
        if financing_pressure >= 72:
            return {
                "actor_type": "company",
                "actor_id": str(company.get("id", "")),
                "actor_name": str(company.get("name", "")),
                "district": district_name,
                "target_asset": stock_name,
                "kind": "bridge_loan",
                "weight": financing_pressure,
                "public_line": f"{company.get('name', '公司')} 开始四处找过桥钱，先保账面不断气。",
                "hidden_line": f"{company.get('name', '公司')} 把 {stock_name or district_name} 的仓位压紧了。",
            }
        if wage_pressure >= 68:
            return {
                "actor_type": "company",
                "actor_id": str(company.get("id", "")),
                "actor_name": str(company.get("name", "")),
                "district": district_name,
                "target_asset": stock_name,
                "kind": "cut_shift",
                "weight": wage_pressure,
                "public_line": f"{company.get('name', '公司')} 开始砍班次，工人先闻到了风。",
                "hidden_line": f"{company.get('name', '公司')} 想靠减班把成本压下去。",
            }
        if order_pressure >= 66 and inventory_state == "tight":
            return {
                "actor_type": "company",
                "actor_id": str(company.get("id", "")),
                "actor_name": str(company.get("name", "")),
                "district": district_name,
                "target_asset": stock_name,
                "kind": "overtime_push",
                "weight": order_pressure,
                "public_line": f"{company.get('name', '公司')} 连夜加班抢单，{stock_name or district_name} 先热了一截。",
                "hidden_line": f"{company.get('name', '公司')} 拿工时去换订单。",
            }
        if trigger == "end_day" and float(company.get("media_sensitivity", 0.0)) >= 0.7 and company_state.get("operating_state") == "strained":
            return {
                "actor_type": "company",
                "actor_id": str(company.get("id", "")),
                "actor_name": str(company.get("name", "")),
                "district": district_name,
                "target_asset": stock_name,
                "kind": "bury_story",
                "weight": float(company.get("media_sensitivity", 0.0)) * 100.0,
                "public_line": f"{company.get('name', '公司')} 正在压消息，想把坏账和坏人一起盖住。",
                "hidden_line": f"{company.get('name', '公司')} 不想让报馆先闻到味。",
            }
        return None

    def _execute_company_action(self, action: dict[str, Any]) -> None:
        company = self._find_by_id(self.state.get("companies", []), str(action.get("actor_id", "")))
        if not company:
            return
        company["active_move"] = str(action.get("kind", ""))
        stock_name = str(company.get("stock_name", ""))
        district_name = str(company.get("district", ""))
        linked_npcs = self._linked_npcs_for_company(str(company.get("id", "")))
        kind = str(action.get("kind", ""))
        if kind == "bridge_loan":
            company["financing_pressure"] = max(8.0, float(company.get("financing_pressure", 45.0)) - 8.0)
            company["payroll_delay"] = max(0.0, float(company.get("payroll_delay", 0.0)) - 10.0)
            company["credit_line"] = min(100.0, float(company.get("credit_line", 30.0)) + 8.0)
            self.state["market_pressure"]["stocks"][stock_name] = float(self.state["market_pressure"]["stocks"].get(stock_name, 0.0)) - 0.05
            self.state["macro"]["economy_heat"] = max(0, int(self.state["macro"].get("economy_heat", 50)) - 1)
            self._bump_district_signal(district_name, "fear", 0.08)
            self._bump_district_signal(district_name, "liquidity", 0.05)
            for npc in linked_npcs[:4]:
                npc["player_trust"] = max(0.0, float(npc.get("player_trust", 0.0)) - 1.5)
                npc["anxiety"] = min(100.0, float(npc.get("anxiety", 0.0)) + 4.0)
        elif kind == "cut_shift":
            company["wage_pressure"] = max(10.0, float(company.get("wage_pressure", 35.0)) - 4.0)
            company["payroll_delay"] = min(100.0, float(company.get("payroll_delay", 0.0)) + 6.0)
            self.state["macro"]["worker_unrest"] = min(100, int(self.state["macro"].get("worker_unrest", 50)) + 2)
            self._bump_district_signal(district_name, "labor_heat", 0.14)
            self._bump_district_signal(district_name, "fear", 0.08)
            self.state["market_pressure"]["stocks"][stock_name] = float(self.state["market_pressure"]["stocks"].get(stock_name, 0.0)) - 0.03
            for npc in linked_npcs[:4]:
                npc["job_security"] = max(8.0, float(npc.get("job_security", 50.0)) - 8.0)
                npc["anxiety"] = min(100.0, float(npc.get("anxiety", 0.0)) + 10.0)
                npc["debt"] = min(180, int(npc.get("debt", 0)) + 1)
        elif kind == "overtime_push":
            company["order_pressure"] = max(12.0, float(company.get("order_pressure", 50.0)) - 6.0)
            company["inventory"] = max(8, int(company.get("inventory", 60)) - 6)
            company["payroll_delay"] = max(0.0, float(company.get("payroll_delay", 0.0)) - 4.0)
            self.state["market_pressure"]["stocks"][stock_name] = float(self.state["market_pressure"]["stocks"].get(stock_name, 0.0)) + 0.05
            self._bump_district_signal(district_name, "trade_heat", 0.12)
            self._bump_district_signal(district_name, "labor_heat", 0.08)
            for npc in linked_npcs[:4]:
                npc["fatigue"] = min(100, int(npc.get("fatigue", 0)) + 8)
                npc["cash"] = int(npc.get("cash", 0)) + 1
                npc["job_security"] = min(100.0, float(npc.get("job_security", 0.0)) + 2.5)
        elif kind == "bury_story":
            self.state["macro"]["media_sentiment"] = max(0, int(self.state["macro"].get("media_sentiment", 50)) - 2)
            self.state["market_pressure"]["stocks"][stock_name] = float(self.state["market_pressure"]["stocks"].get(stock_name, 0.0)) + 0.02
            self._bump_district_signal(district_name, "gossip", 0.1)
            for npc in linked_npcs[:3]:
                npc["loyalty"] = min(100, int(npc.get("loyalty", 0)) + 3)
                npc["player_trust"] = max(0.0, float(npc.get("player_trust", 0.0)) - 1.0)

    def _decide_family_action(self, family_move: dict[str, Any], trigger: str) -> dict[str, Any] | None:
        family = self._find_by_id(self.state.get("families", []), str(family_move.get("id", "")))
        if not family:
            return None
        target_asset = str(family_move.get("target_asset", ""))
        relation = int(family_move.get("relation", 0))
        operation_style = str(family_move.get("operation_style", ""))
        controlled_states = [
            state for state in self.state.get("company_states", [])
            if str(state.get("id", "")) in set(str(value) for value in family_move.get("controlled_company_ids", []))
        ]
        strained = [state for state in controlled_states if str(state.get("operating_state", "")) == "strained"]
        if strained and int(family.get("media_power", 0)) >= 60:
            return {
                "actor_type": "family",
                "actor_id": str(family.get("id", "")),
                "actor_name": str(family.get("name", "")),
                "district": str(strained[0].get("district", "交易所")),
                "target_asset": target_asset,
                "kind": "spin_campaign",
                "weight": float(strained[0].get("pressure_score", 60.0)),
                "public_line": f"{family.get('name', '家族')} 开始往报馆和街口塞话，想把 {target_asset or '坏味'} 包成故事。",
                "hidden_line": f"{family.get('name', '家族')} 正把火往别处带。",
            }
        if float(family.get("risk_appetite", 0.5)) >= 0.62 and target_asset:
            return {
                "actor_type": "family",
                "actor_id": str(family.get("id", "")),
                "actor_name": str(family.get("name", "")),
                "district": "交易所",
                "target_asset": target_asset,
                "kind": "support_asset" if relation >= -2 else "lean_short",
                "weight": float(family_move.get("pressure_score", 0.6)) * 100.0,
                "public_line": f"{family.get('name', '家族')} 开始围着 {target_asset} 布局，盘口味道变得更重了。",
                "hidden_line": f"{family.get('name', '家族')} 想借 {target_asset} 试市场温度。",
            }
        if trigger == "end_day" and "压" in operation_style:
            return {
                "actor_type": "family",
                "actor_id": str(family.get("id", "")),
                "actor_name": str(family.get("name", "")),
                "district": "工厂区" if "工" in operation_style else "交易所",
                "target_asset": target_asset,
                "kind": "tighten_books",
                "weight": float(family_move.get("pressure_score", 0.5)) * 100.0,
                "public_line": f"{family.get('name', '家族')} 收紧账本，街上借钱和用工都会先变冷。",
                "hidden_line": f"{family.get('name', '家族')} 想先把现金抱紧。",
            }
        return None

    def _execute_family_action(self, action: dict[str, Any]) -> None:
        family = self._find_by_id(self.state.get("families", []), str(action.get("actor_id", "")))
        if not family:
            return
        family_name = str(family.get("name", ""))
        target_asset = str(action.get("target_asset", ""))
        district_name = str(action.get("district", "交易所"))
        linked_npcs = self._linked_npcs_for_family(family_name)
        kind = str(action.get("kind", ""))
        if kind == "spin_campaign":
            self.state["macro"]["media_sentiment"] = min(100, int(self.state["macro"].get("media_sentiment", 50)) + 2)
            if target_asset in self.state["market_pressure"]["stocks"]:
                self.state["market_pressure"]["stocks"][target_asset] = float(self.state["market_pressure"]["stocks"].get(target_asset, 0.0)) + 0.04
            self._bump_district_signal(district_name, "gossip", 0.16)
            self._bump_district_signal(district_name, "liquidity", 0.05)
        elif kind == "support_asset":
            if target_asset in self.state["market_pressure"]["stocks"]:
                self.state["market_pressure"]["stocks"][target_asset] = float(self.state["market_pressure"]["stocks"].get(target_asset, 0.0)) + 0.06
            if target_asset in self.state["market_pressure"]["goods"]:
                self.state["market_pressure"]["goods"][target_asset] = float(self.state["market_pressure"]["goods"].get(target_asset, 0.0)) + 0.05
            self._bump_district_signal(district_name, "liquidity", 0.14)
            for company in self.state.get("companies", []):
                if str(company.get("family_owner", "")) == family_name:
                    company["credit_line"] = min(100.0, float(company.get("credit_line", 30.0)) + 5.0)
        elif kind == "lean_short":
            if target_asset in self.state["market_pressure"]["stocks"]:
                self.state["market_pressure"]["stocks"][target_asset] = float(self.state["market_pressure"]["stocks"].get(target_asset, 0.0)) - 0.06
            if target_asset in self.state["market_pressure"]["goods"]:
                self.state["market_pressure"]["goods"][target_asset] = float(self.state["market_pressure"]["goods"].get(target_asset, 0.0)) - 0.05
            self._bump_district_signal(district_name, "fear", 0.1)
            self._bump_district_signal(district_name, "gossip", 0.06)
        elif kind == "tighten_books":
            self.state["macro"]["interest_rate"] = round(min(5.5, float(self.state["macro"].get("interest_rate", 2.0)) + 0.08), 2)
            self.state["macro"]["economy_heat"] = max(0, int(self.state["macro"].get("economy_heat", 50)) - 1)
            self._bump_district_signal(district_name, "liquidity", 0.08)
            self._bump_district_signal(district_name, "fear", 0.06)
            for company in self.state.get("companies", []):
                if str(company.get("family_owner", "")) == family_name:
                    company["payroll_delay"] = min(100.0, float(company.get("payroll_delay", 0.0)) + 4.0)
        for npc in linked_npcs[:4]:
            npc["loyalty"] = min(100, int(npc.get("loyalty", 0)) + 2)
            if kind in {"lean_short", "tighten_books"}:
                npc["anxiety"] = min(100.0, float(npc.get("anxiety", 0.0)) + 4.0)
        family["public_action"] = str(action.get("public_line", family.get("public_action", "")))
        family["hidden_action"] = str(action.get("hidden_line", family.get("hidden_action", "")))

    def _linked_npcs_for_company(self, company_id: str) -> list[dict[str, Any]]:
        if not company_id:
            return []
        linked = [npc for npc in self.state.get("npcs", []) if str(npc.get("company_id", "")) == company_id]
        if linked:
            return linked
        company = self._find_by_id(self.state.get("companies", []), company_id)
        district_name = str(company.get("district", "")) if company else ""
        return [npc for npc in self.state.get("npcs", []) if str(npc.get("district", "")) == district_name]

    def _linked_npcs_for_family(self, family_name: str) -> list[dict[str, Any]]:
        return [npc for npc in self.state.get("npcs", []) if str(npc.get("family_affiliation", "")) == family_name]

    def _rebuild_family_moves(self) -> None:
        moves: list[dict[str, Any]] = []
        relations = self.state.get("player", {}).get("family_relations", {})
        family_briefings = self.state.get("family_briefings", {})
        for family in self.state.get("families", []):
            family_name = str(family.get("name", ""))
            controlled = [state for state in self.state.get("company_states", []) if str(state.get("family_owner", "")) == family_name]
            target_stock, target_good = self._family_focus_targets(family)
            briefing = family_briefings.get(family_name, {})
            public_action = str(briefing.get("public_line", "")) or self._family_public_move(family, controlled, target_stock or target_good)
            hidden_action = str(briefing.get("hidden_line", "")) or self._family_hidden_move(family, controlled, target_stock or target_good)
            recent_briefs = copy.deepcopy(self._entity_brief_history("family_brief_history", family_name))
            moves.append(
                {
                    "id": str(family.get("id", "")),
                    "name": family_name,
                    "public_action": public_action,
                    "hidden_action": hidden_action,
                    "target_asset": target_stock or target_good,
                    "player_attitude": str(family.get("player_attitude", "")),
                    "relation": int(relations.get(family_name, 0)),
                    "allies": list(family.get("allies", [])),
                    "enemies": list(family.get("enemies", [])),
                    "pressure_score": round(abs(float(self.state["market_pressure"]["families"].get(family_name, 0.0))) + float(family.get("risk_appetite", 0.5)) * 0.5, 3),
                    "controlled_company_ids": [str(company.get("id", "")) for company in controlled],
                    "operation_style": str(family.get("strategy", family.get("public_action", "观望"))),
                    "capital_posture": "紧" if float(family.get("liquidity_preference", 0.5)) >= 0.62 else "压" if float(family.get("risk_appetite", 0.5)) >= 0.62 else "守",
                    "briefing_focus": str(briefing.get("focus", family.get("llm_focus", family.get("strategy", "")))),
                    "briefing_signal": str(briefing.get("signal", self._family_signal_from_state(family))),
                    "briefing_source": str(briefing.get("source", "rule")),
                    "recent_briefs": recent_briefs,
                    "brief_history_summary": self._brief_history_summary(recent_briefs, ("public_line", "focus", "hidden_line")),
                }
            )
        self.state["family_moves"] = moves

    def _rebuild_npc_truth_profile(self) -> None:
        profiles: dict[str, dict[str, Any]] = {}
        for npc in self.state.get("npcs", []):
            pressure = max(0.0, min(1.0, (float(npc.get("debt", 0)) / 120.0) + float(npc.get("hunger", 0)) / 180.0 + float(npc.get("anxiety", 0.0)) / 180.0))
            relation = int(npc.get("player_relation", 0))
            loyalty = float(npc.get("loyalty", 0.0))
            truthfulness = max(0.08, min(0.94, float(npc.get("info_reliability", 0.5)) + relation * 0.018 - loyalty * 0.0015 - pressure * 0.22))
            confidence = max(0.12, min(0.96, 0.38 + loyalty * 0.002 + (100.0 - float(npc.get("rumor_sensitivity", 0.4)) * 100.0) * 0.003 - pressure * 0.1))
            profiles[str(npc.get("id", ""))] = {
                "truthfulness": round(truthfulness, 3),
                "confidence": round(confidence, 3),
                "economic_pressure": round(pressure, 3),
                "bias": str(npc.get("family_affiliation", "")) if str(npc.get("family_affiliation", "")) else str(npc.get("stance", "观望")),
                "domains": list(npc.get("information_domain", [])),
            }
        self.state["npc_truth_profile"] = profiles

    def _build_npc_cards(self) -> list[dict[str, Any]]:
        cards: list[dict[str, Any]] = []
        truth_profiles = self.state.get("npc_truth_profile", {})
        spin_map = self.state.get("npc_spin_map", {})
        for npc in self.state.get("npcs", []):
            profile = truth_profiles.get(str(npc.get("id", "")), {})
            position_kind, position_name, position_qty, position_bias = self._dominant_position(npc)
            economic_pressure = round(float(profile.get("economic_pressure", 0.0)), 3)
            company = self._find_by_id(self.state.get("companies", []), str(npc.get("company_id", "")))
            family = self._find_by_name(self.state.get("families", []), str(npc.get("family_affiliation", ""))) if str(npc.get("family_affiliation", "")) else None
            institution_note = self._npc_institution_note(company, family)
            spin = spin_map.get(str(npc.get("id", "")), {})
            memory_summary = self._npc_memory_summary(npc)
            relation_status = self._npc_player_status(npc)
            brief_history = copy.deepcopy(self._entity_brief_history("npc_brief_history", str(npc.get("id", ""))))
            cards.append(
                {
                    "id": str(npc.get("id", "")),
                    "name": str(npc.get("name", "")),
                    "district": str(npc.get("district", "")),
                    "role": str(npc.get("role", "")),
                    "cash": int(npc.get("cash", 0)),
                    "debt": int(npc.get("debt", 0)),
                    "hunger": int(npc.get("hunger", 0)),
                    "inventory": copy.deepcopy(npc.get("inventory", {})),
                    "inventory_summary": self._npc_inventory_summary(npc),
                    "job_security": round(float(npc.get("job_security", 0.0)), 2),
                    "player_trust": round(float(npc.get("player_trust", 0.0)), 2),
                    "economic_pressure": economic_pressure,
                    "truthfulness": round(float(profile.get("truthfulness", 0.5)), 3),
                    "confidence": round(float(profile.get("confidence", 0.5)), 3),
                    "domains": list(profile.get("domains", [])),
                    "position_kind": position_kind,
                    "position_name": position_name,
                    "position_qty": position_qty,
                    "position_bias": position_bias,
                    "institution_note": institution_note,
                    "llm_line": str(spin.get("line", "")),
                    "llm_stance": str(spin.get("stance", npc.get("stance", ""))),
                    "llm_market_tilt": str(spin.get("market_tilt", self._npc_market_tilt(npc))),
                    "llm_source": str(spin.get("source", "rule")),
                    "memory_summary": memory_summary,
                    "relation_status": relation_status,
                    "player_memory": copy.deepcopy(self._npc_player_memory(npc)),
                    "agent_prompt": str(npc.get("agent_prompt", "")),
                    "agent_budget_left": int(npc.get("agent_budget", {}).get("calls_left", 0)),
                    "agent_tool_policy": copy.deepcopy(npc.get("agent_tool_policy", [])),
                    "agent_memory": copy.deepcopy(list(npc.get("agent_memory", []))[:4]),
                    "agent_policy": copy.deepcopy(npc.get("agent_policy", {})),
                    "brief_history": brief_history,
                    "brief_history_summary": self._brief_history_summary(brief_history, ("line", "stance")),
                    "llm_refresh_cadence": int(npc.get("llm_refresh_cadence", 1)),
                    "last_llm_brief_pulse": int(npc.get("last_llm_brief_pulse", -1)),
                    "personal_summary": self._npc_personal_summary(npc, economic_pressure, position_kind, position_name, position_bias, institution_note),
                }
            )
        cards.sort(key=lambda item: (float(item.get("economic_pressure", 0.0)), int(item.get("debt", 0))), reverse=True)
        return cards

    def _npc_personal_summary(
        self,
        npc: dict[str, Any],
        economic_pressure: float,
        position_kind: str,
        position_name: str,
        position_bias: str,
        institution_note: str = "",
    ) -> str:
        summary = f"现金 {int(npc.get('cash', 0))} · 负债 {int(npc.get('debt', 0))} · 压力 {int(round(economic_pressure * 100))}%"
        if position_name:
            summary += f" · {position_kind}:{position_name}({position_bias})"
        if institution_note:
            summary += f" · {institution_note}"
        return summary

    def _npc_institution_note(self, company: dict[str, Any] | None, family: dict[str, Any] | None) -> str:
        if company and str(company.get("active_move", "")):
            return f"公司:{self._institution_action_label(str(company.get('active_move', '')))}"
        if family and str(family.get("public_action", "")):
            return f"家族:{str(family.get('public_action', ''))[:8]}"
        return ""

    def _npc_personal_topics(self, npc: dict[str, Any]) -> list[dict[str, Any]]:
        topics: list[dict[str, Any]] = []
        npc_id = str(npc.get("id", ""))
        district_name = str(npc.get("district", ""))
        truth_profile = self.state.get("npc_truth_profile", {}).get(npc_id, {})
        economic_pressure = float(truth_profile.get("economic_pressure", 0.0))
        if economic_pressure >= 0.32 or float(npc.get("debt", 0)) >= float(npc.get("housing_cost", 4)) * 3:
            topics.append(
                {
                    "id": f"topic_livelihood_{npc_id}",
                    "kind": "livelihood",
                    "district": district_name,
                    "label": f"{npc.get('name', '这人')}的账本",
                    "summary": f"{npc.get('name', '对方')}最近被房租、工钱和欠账一起卡着，嘴上再硬也藏不住日子发紧。",
                    "heat": round(0.18 + economic_pressure, 3),
                    "tags": ["生计", district_name, str(npc.get("role", ""))],
                    "npc_ids": [npc_id],
                    "approaches": ["friendly", "cautious", "hardball"],
                    "impacts": {
                        "goods": self._personal_topic_goods_impact(npc),
                        "stocks": {},
                        "macro": {"worker_unrest": 0.6 if str(npc.get("income_type", "")) == "wage" else 0.2},
                        "families": {},
                    },
                }
            )
        if int(npc.get("hunger", 0)) >= 58:
            topics.append(
                {
                    "id": f"topic_ration_{npc_id}",
                    "kind": "ration",
                    "district": district_name,
                    "label": f"{npc.get('name', '这人')}的口粮",
                    "summary": f"{npc.get('name', '对方')}眼下先惦记的是口粮和今天能不能吃热的，很多判断都会往保命那边偏。",
                    "heat": round(0.16 + int(npc.get("hunger", 0)) / 120.0, 3),
                    "tags": ["口粮", district_name],
                    "npc_ids": [npc_id],
                    "approaches": ["friendly", "cautious"],
                    "impacts": {
                        "goods": {"面包": 0.05, "罐头": 0.03},
                        "stocks": {},
                        "macro": {"worker_unrest": 0.4},
                        "families": {},
                    },
                }
            )
        position_kind, position_name, position_qty, position_bias = self._dominant_position(npc)
        if position_name and position_qty > 0:
            topics.append(
                {
                    "id": f"topic_position_{npc_id}",
                    "kind": "position",
                    "district": district_name,
                    "label": f"{npc.get('name', '这人')}押着的{position_name}",
                    "summary": f"{npc.get('name', '对方')}手里压着 {position_name} x{position_qty}，嘴上的方向多半会往“{position_bias}”那边靠。",
                    "heat": round(0.22 + min(0.45, position_qty * 0.08), 3),
                    "tags": ["持仓", district_name, position_name],
                    "npc_ids": [npc_id],
                    "approaches": ["cautious", "friendly", "hardball"],
                    "impacts": self._personal_position_impacts(position_kind, position_name, position_bias),
                }
            )
        return topics

    def _personal_topic_goods_impact(self, npc: dict[str, Any]) -> dict[str, float]:
        district_name = str(npc.get("district", ""))
        if district_name == "工厂区":
            return {"煤": 0.04}
        if district_name == "港口":
            return {"罐头": 0.04}
        return {"面包": 0.05}

    def _dominant_position(self, npc: dict[str, Any]) -> tuple[str, str, int, str]:
        stock_positions = {str(name): int(value) for name, value in dict(npc.get("stock_positions", {})).items() if int(value) > 0}
        if stock_positions:
            name, qty = max(stock_positions.items(), key=lambda item: item[1])
            bias = "喊多" if float(npc.get("greed_drive", npc.get("greed", 0))) >= float(npc.get("anxiety", npc.get("fear", 0))) else "喊空"
            return "stock", name, qty, bias
        goods_positions = {str(name): int(value) for name, value in dict(npc.get("goods_positions", {})).items() if int(value) > 0}
        if goods_positions:
            name, qty = max(goods_positions.items(), key=lambda item: item[1])
            bias = "囤着" if float(npc.get("anxiety", npc.get("fear", 0))) >= 40 else "找价差"
            return "goods", name, qty, bias
        return "", "", 0, ""

    def _personal_position_impacts(self, position_kind: str, position_name: str, position_bias: str) -> dict[str, Any]:
        if position_kind == "stock":
            delta = 0.05 if position_bias == "喊多" else -0.05
            return {"goods": {}, "stocks": {position_name: delta}, "macro": {"media_sentiment": 0.5}, "families": {}}
        delta = 0.04 if position_bias in {"囤着", "找价差"} else -0.03
        return {"goods": {position_name: delta}, "stocks": {}, "macro": {"economy_heat": 0.2}, "families": {}}

    def _truth_metrics_for_topic(self, npc: dict[str, Any], topic: dict[str, Any], approach: str, intent: str) -> dict[str, Any]:
        base = copy.deepcopy(self.state.get("npc_truth_profile", {}).get(str(npc.get("id", "")), {}))
        if not base:
            self._rebuild_npc_truth_profile()
            base = copy.deepcopy(self.state.get("npc_truth_profile", {}).get(str(npc.get("id", "")), {}))
        truthfulness = float(base.get("truthfulness", 0.5))
        confidence = float(base.get("confidence", 0.5))
        domains = [str(value) for value in base.get("domains", [])]
        memory = self._npc_player_memory(npc)
        kind = str(topic.get("kind", ""))
        if kind == "family" and str(npc.get("family_affiliation", "")):
            truthfulness -= 0.12
        if kind == "company" and "company" not in domains and "labor" not in domains:
            confidence -= 0.08
        if kind in {"livelihood", "ration"}:
            confidence += 0.07 if ("labor" in domains or "ration" in domains) else -0.03
            truthfulness += 0.05 if float(base.get("economic_pressure", 0.0)) >= 0.3 else -0.02
        if kind == "position":
            confidence += 0.08 if ("stock" in domains or "trade" in domains) else -0.04
            truthfulness -= 0.06 if float(base.get("economic_pressure", 0.0)) >= 0.45 else 0.0
        if kind == "asset" and "stock" in domains:
            confidence += 0.08
        if kind == "institution":
            confidence += 0.06 if any(domain in domains for domain in ["family", "company", "media", "labor"]) else -0.04
            if str(npc.get("family_affiliation", "")) and str(npc.get("family_affiliation", "")) in [str(value) for value in topic.get("tags", [])]:
                truthfulness -= 0.08
        confidence += min(0.08, int(memory.get("intel_bought", 0)) * 0.012)
        truthfulness += min(0.1, int(memory.get("friendly_count", 0)) * 0.015)
        truthfulness -= min(0.16, float(memory.get("pressure_from_player", 0.0)) * 0.03)
        if str(memory.get("last_topic_id", "")) == str(topic.get("id", "")):
            confidence += 0.05
        if approach == "friendly":
            truthfulness += 0.06
        elif approach == "hardball":
            confidence -= 0.06
            truthfulness -= 0.08
        if "问工作" in intent and "labor" in domains:
            confidence += 0.06
        if "问谁在放风" in intent or kind == "panic":
            truthfulness -= max(0.0, float(base.get("economic_pressure", 0.0)) * 0.08)
        return {
            "truthfulness": round(max(0.08, min(0.95, truthfulness)), 3),
            "confidence": round(max(0.08, min(0.96, confidence)), 3),
            "bias": str(base.get("bias", npc.get("stance", "观望"))),
            "domains": domains,
            "economic_pressure": float(base.get("economic_pressure", 0.0)),
            "player_memory_summary": self._npc_memory_summary(npc),
            "player_memory": copy.deepcopy(memory),
        }

    def _spin_intel_packet(self, packet: dict[str, Any], npc: dict[str, Any], truth_profile: dict[str, Any], topic: dict[str, Any]) -> dict[str, Any]:
        spun = copy.deepcopy(packet)
        truthfulness = float(truth_profile.get("truthfulness", 0.5))
        confidence = float(truth_profile.get("confidence", 0.5))
        if truthfulness < 0.32:
            strongest_stock = next(iter(spun.get("stocks_delta", {})), "")
            strongest_good = next(iter(spun.get("goods_delta", {})), "")
            if strongest_stock:
                spun["stocks_delta"][strongest_stock] = round(float(spun["stocks_delta"][strongest_stock]) * -0.45, 3)
            if strongest_good:
                spun["goods_delta"][strongest_good] = round(float(spun["goods_delta"][strongest_good]) * -0.4, 3)
            spun["line"] = f"{npc.get('name', '那人')} 把 {topic.get('label', '这件事')} 说得很满，听着像在带方向。"
        elif confidence < 0.42:
            spun["line"] = f"{npc.get('name', '那人')} 只肯递半句：{topic.get('summary', spun.get('line', '街头有风声。'))}"
            spun["goods_delta"] = {key: round(float(value) * 0.55, 3) for key, value in spun.get("goods_delta", {}).items()}
            spun["stocks_delta"] = {key: round(float(value) * 0.55, 3) for key, value in spun.get("stocks_delta", {}).items()}
        return spun

    def _describe_world_effects(self, intel: dict[str, Any], strength: float) -> str:
        if strength <= 0.12:
            return "这次只摸到态度，街上的价格和情绪还没被你撬动。"
        pieces: list[str] = []
        if intel.get("goods_delta"):
            goods_text = "、".join(f"{name}{'涨' if float(delta) > 0 else '跌'}" for name, delta in intel["goods_delta"].items())
            pieces.append(f"货物风向：{goods_text}")
        if intel.get("stocks_delta"):
            stock_text = "、".join(f"{name}{'被捧' if float(delta) > 0 else '被压'}" for name, delta in intel["stocks_delta"].items())
            pieces.append(f"盘口：{stock_text}")
        if intel.get("family_delta"):
            family_text = "、".join(f"{name}{'更热' if float(delta) > 0 else '更紧'}" for name, delta in intel["family_delta"].items())
            pieces.append(f"家族：{family_text}")
        if intel.get("macro_delta"):
            macro_text = "、".join(str(key) for key in intel["macro_delta"].keys())
            pieces.append(f"城里气压：{macro_text}")
        return "；".join(pieces[:3]) if pieces else "这条话已经进了街区风向。"

    def _build_district_topic_map(self) -> dict[str, list[dict[str, Any]]]:
        grouped: dict[str, list[dict[str, Any]]] = {}
        for topic in self.state.get("talk_topics", []):
            district_name = str(topic.get("district", ""))
            if not district_name:
                continue
            grouped.setdefault(district_name, []).append(copy.deepcopy(topic))
        for district_name, items in grouped.items():
            items.sort(key=lambda item: float(item.get("heat", 0.0)), reverse=True)
            grouped[district_name] = items[:4]
        return grouped

    def _build_city_news(self) -> list[dict[str, Any]]:
        items: list[dict[str, Any]] = []
        seen: set[tuple[str, str]] = set()
        for news in self.state.get("global_news", []):
            title = str(news.get("title", "")).strip()
            body = str(news.get("body", "")).strip()
            if not title or not body:
                continue
            key = (title, body)
            if key in seen:
                continue
            seen.add(key)
            items.append(copy.deepcopy(news))
            if len(items) >= 4:
                return items
        for action in self.state.get("institution_actions", []):
            if str(action.get("scope", "district")) != "city":
                continue
            title = str(action.get("headline", "")).strip()
            body = str(action.get("news_body", action.get("public_line", ""))).strip()
            if not title or not body:
                continue
            key = (title, body)
            if key in seen:
                continue
            seen.add(key)
            items.append(
                {
                    "title": title,
                    "body": body,
                    "tags": list(action.get("tags", [])),
                    "scope": "city",
                    "tone": str(action.get("tone", "cold")),
                }
            )
            if len(items) >= 4:
                break
        return items

    def _institution_topics(self) -> list[dict[str, Any]]:
        topics: list[dict[str, Any]] = []
        for action in self.state.get("institution_actions", [])[:4]:
            district_name = str(action.get("district", ""))
            if not district_name:
                continue
            actor_type = str(action.get("actor_type", ""))
            actor_name = str(action.get("actor_name", "机构"))
            target_asset = str(action.get("target_asset", ""))
            npc_ids = [npc["id"] for npc in self._linked_npcs_for_company(str(action.get("actor_id", "")))] if actor_type == "company" else [
                npc["id"] for npc in self._linked_npcs_for_family(actor_name)
            ]
            topics.append(
                {
                    "id": f"topic_institution_{actor_type}_{action.get('actor_id', actor_name)}_{action.get('kind', '')}",
                    "kind": "institution",
                    "district": district_name,
                    "label": f"{actor_name} 刚出的手",
                    "summary": str(action.get("public_line", "")),
                    "heat": round(0.22 + float(action.get("effect_score", 0.4)), 3),
                    "tags": list(action.get("tags", ["机构", actor_name])),
                    "npc_ids": npc_ids,
                    "approaches": ["cautious", "friendly", "hardball"],
                    "impacts": self._institution_topic_impacts(action, target_asset),
                }
            )
        return topics

    def _institution_topic_impacts(self, action: dict[str, Any], target_asset: str) -> dict[str, Any]:
        kind = str(action.get("kind", ""))
        goods: dict[str, float] = {}
        stocks: dict[str, float] = {}
        macro: dict[str, float] = {}
        families: dict[str, float] = {}
        direction = 1.0
        if kind in {"lean_short", "cut_shift", "tighten_books"}:
            direction = -1.0
        if target_asset in self.state.get("market_pressure", {}).get("stocks", {}):
            stocks[target_asset] = round(0.05 * direction, 3)
        if target_asset in self.state.get("market_pressure", {}).get("goods", {}):
            goods[target_asset] = round(0.04 * direction, 3)
        if kind in {"bridge_loan", "tighten_books"}:
            macro["interest_rate"] = 0.08 if kind == "tighten_books" else -0.04
        if kind in {"cut_shift", "overtime_push"}:
            macro["worker_unrest"] = 0.8 if kind == "cut_shift" else 0.3
        if kind in {"spin_campaign", "bury_story"}:
            macro["media_sentiment"] = 0.8 if kind == "spin_campaign" else -0.5
        if str(action.get("actor_type", "")) == "family":
            families[str(action.get("actor_name", ""))] = 0.07 * direction
        return {"goods": goods, "stocks": stocks, "macro": macro, "families": families}

    def _company_topic_goods_impact(self, company_state: dict[str, Any]) -> dict[str, float]:
        industry = str(company_state.get("name", "")) + str(company_state.get("stock_name", ""))
        if "航" in industry or "港" in industry:
            return {"罐头": 0.05}
        if "矿" in industry or "黑石" in industry:
            return {"煤": 0.06}
        return {"面包": 0.04}

    def _good_chain_bonus(self, good: dict[str, Any]) -> float:
        good_name = str(good.get("name", ""))
        bonus = 0.0
        for company in self.state.get("companies", []):
            industry = str(company.get("industry", "")) + str(company.get("name", ""))
            if good_name == "煤" and ("矿" in industry or "黑石" in industry):
                bonus += (50.0 - float(company.get("inventory", 50))) * 0.0008
            if good_name == "罐头" and ("航" in industry or "港" in industry):
                bonus += (float(company.get("order_pressure", 50)) - 50.0) * 0.001
            if good_name == "面包" and ("报" in industry or "传媒" in industry):
                bonus += (float(self.state["macro"].get("worker_unrest", 50)) - 50.0) * 0.0008
        return round(max(-0.08, min(0.08, bonus)), 4)

    def _company_for_stock(self, stock: dict[str, Any]) -> dict[str, Any] | None:
        stock_name = str(stock.get("name", ""))
        for company in self.state.get("companies", []):
            if str(company.get("stock_name", "")) == stock_name:
                return company
        return None

    def _as_float(self, value: Any, default: float) -> float:
        try:
            return float(value)
        except (TypeError, ValueError):
            return default

    def _stock_macro_bonus(self, stock: dict[str, Any]) -> float:
        media = (float(self.state["macro"].get("media_sentiment", 50)) - 50.0) * (0.002 + self._as_float(stock.get("media_sensitivity", 0.4), 0.4) * 0.002)
        economy = (float(self.state["macro"].get("economy_heat", 50)) - 50.0) * 0.0025
        rate_drag = (float(self.state["macro"].get("interest_rate", 2.0)) - 2.0) * -0.018
        return round(media + economy + rate_drag, 4)

    def _stock_family_bonus(self, stock: dict[str, Any]) -> float:
        family_name = str(stock.get("family_owner", ""))
        pressure = float(self.state.get("market_pressure", {}).get("families", {}).get(family_name, 0.0))
        return round(pressure * 0.35 + self.random.uniform(-0.02, 0.03), 4)

    def _stock_company_bonus(self, stock: dict[str, Any]) -> float:
        company = self._company_for_stock(stock)
        if not company:
            return 0.0
        return round((float(company.get("profit_margin", 0.12)) - 0.12) * 0.8 + (float(company.get("order_pressure", 50.0)) - 50.0) * 0.0018 - (float(company.get("financing_pressure", 45.0)) - 45.0) * 0.0015 - float(company.get("wage_pressure", 35.0)) * 0.0008, 4)

    def _family_company_pressure(self, companies: list[dict[str, Any]]) -> float:
        if not companies:
            return 0.0
        avg_pressure = sum(float(company.get("financing_pressure", 45.0)) + float(company.get("wage_pressure", 35.0)) for company in companies) / (2.0 * len(companies))
        return round((avg_pressure - 45.0) * 0.0016, 4)

    def _family_public_move(self, family: dict[str, Any], companies: list[dict[str, Any]], target: str) -> str:
        if not companies:
            return str(family.get("public_action", "低调观望"))
        hottest = max(companies, key=lambda company: float(company.get("order_pressure", 0.0)) - float(company.get("financing_pressure", 0.0)))
        if float(hottest.get("financing_pressure", 0.0)) >= 70:
            return f"替 {hottest.get('name', target)} 收紧账本"
        if float(hottest.get("order_pressure", 0.0)) >= 68:
            return f"替 {hottest.get('name', target)} 护盘抢单"
        return f"盯住 {target or hottest.get('name', '街头温度')}"

    def _family_hidden_move(self, family: dict[str, Any], companies: list[dict[str, Any]], target: str) -> str:
        if not companies:
            return str(family.get("hidden_action", "沿着街头放风"))
        weakest = max(companies, key=lambda company: float(company.get("wage_pressure", 0.0)) + float(company.get("financing_pressure", 0.0)))
        if float(weakest.get("wage_pressure", 0.0)) >= 65:
            return f"沿着 {weakest.get('district', '街区')} 压住工价口风"
        if float(weakest.get("financing_pressure", 0.0)) >= 60:
            return f"让代理人去试探 {target or weakest.get('stock_name', '盘口')}"
        return f"沿着 {target or weakest.get('name', '街区')} 放风"

    def _push_memory(self, memory_tags: list[str], tag: str) -> list[str]:
        updated = list(memory_tags)
        updated.append(tag)
        return updated[-8:]

    @staticmethod
    def _now_label() -> str:
        return datetime.now().strftime("%H:%M:%S")
