from __future__ import annotations

import unittest

from services.engine import WorldEngine


class WorldEngineTest(unittest.TestCase):
    def setUp(self) -> None:
        self.engine = WorldEngine(pulse_interval_seconds=999)

    def test_bootstrap_contains_expected_world(self) -> None:
        snapshot = self.engine.snapshot()
        self.assertEqual(snapshot["day"], 1)
        self.assertEqual(len(snapshot["goods"]), 3)
        self.assertEqual(len(snapshot["stocks"]), 3)
        self.assertEqual(len(snapshot["npcs"]), 36)
        self.assertEqual(snapshot["player"]["cash"], 1_000_000)
        self.assertGreaterEqual(max(int(npc.get("cash", 0)) for npc in snapshot["npcs"]), 150_000)
        self.assertTrue(snapshot["global_news"])
        self.assertTrue(snapshot["ambient_speeches"])
        self.assertTrue(snapshot["company_states"])
        self.assertTrue(snapshot["family_moves"])
        self.assertTrue(snapshot["npc_truth_profile"])
        self.assertTrue(snapshot["npc_cards"])
        self.assertIn("institution_actions", snapshot)

    def test_boot_does_not_preheat_citywide_gossip(self) -> None:
        snapshot = self.engine.snapshot()
        self.assertTrue(all(float(row.get("gossip", 0.0)) == 0.0 for row in snapshot["district_signals"].values()))
        self.assertFalse(snapshot["active_topics"])
        self.assertLessEqual(sum(1 for npc in snapshot["npcs"] if npc["activity"] in {"assembling", "gathering"}), 1)

    def test_persona_prompt_profiles_are_loaded_into_npcs(self) -> None:
        snapshot = self.engine.snapshot()
        npc_01 = next(row for row in snapshot["npcs"] if row["id"] == "npc_01")
        npc_36 = next(row for row in snapshot["npcs"] if row["id"] == "npc_36")
        self.assertIn("prompt_profile", npc_01)
        self.assertIn("海藻资本", npc_01["agent_prompt"])
        self.assertIn("系统硬指标", npc_36["agent_prompt"])
        self.assertIn("巴德", npc_36["agent_prompt"])

    def test_npc_agent_prompt_no_longer_assumes_player_is_turtle(self) -> None:
        prompt = next(row for row in self.engine.snapshot()["npcs"] if row["id"] == "npc_01")["agent_prompt"]
        self.assertIn("玩家只是外来玩家或来访者", prompt)
        self.assertNotIn("那只乌龟", prompt)

    def test_player_talk_sends_recent_conversation_history_to_llm(self) -> None:
        seen_payloads: list[dict[str, object]] = []

        def fake_dialogue(payload: dict[str, object]) -> dict[str, object]:
            seen_payloads.append(payload)
            return {"lines": [str(payload.get("player_input", "")) or "……", "我记着你刚才问过这事。"], "stance": "谨慎", "truthfulness": 0.6}

        self.engine.ark.generate_dialogue_turn = fake_dialogue  # type: ignore[method-assign]
        self.engine.player_talk("npc_01", "贫民街", player_input="先说说粮价。")
        self.engine.player_talk("npc_01", "贫民街", player_input="我刚才问的那事，你改口没有？")
        self.assertGreaterEqual(len(seen_payloads), 2)
        second_payload = seen_payloads[-1]
        relationship_memory = dict(second_payload.get("relationship_memory", {}))
        history = list(relationship_memory.get("conversation_history", []))
        self.assertTrue(history)
        self.assertIn("先说说粮价", str(history[0].get("speaker_line", "")))

    def test_player_talk_builds_local_memory_bank_for_npc(self) -> None:
        self.engine.ark.generate_dialogue_turn = lambda payload: {"lines": [str(payload.get("player_input", "")) or "……", "这话我先记在心里。"], "stance": "谨慎", "truthfulness": 0.58}  # type: ignore[method-assign]
        self.engine.player_talk("npc_01", "贫民街", player_input="你先记住我今天问过库存。")
        npc = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_01")
        self.assertTrue(npc["dialogue_history"])
        self.assertTrue(npc["local_memory_bank"])
        self.assertEqual(npc["dialogue_history"][0]["counterpart_id"], "player")
        self.assertIn("库存", npc["local_memory_bank"][0]["summary"])

    def test_gift_money_transfers_real_cash_and_can_flip_ordinary_npc(self) -> None:
        npc = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_10")
        player_cash_before = int(self.engine.state["player"]["cash"])
        npc_cash_before = int(npc["cash"])
        result = self.engine.action("gift_money", str(npc["district"]), {"npc_id": str(npc["id"]), "amount": 10_000})
        npc_after = next(row for row in result.world_state["npcs"] if row["id"] == str(npc["id"]))
        self.assertEqual(result.world_state["player"]["cash"], player_cash_before - 10_000)
        self.assertEqual(int(npc_after["cash"]), npc_cash_before + 10_000)
        self.assertTrue(npc_after["player_memory"]["bought_over"])
        self.assertEqual(next(card for card in result.world_state["npc_cards"] if card["id"] == str(npc["id"]))["relation_status"], "被你收买")

    def test_buy_intel_unlocks_after_money_and_moves_real_cash(self) -> None:
        npc = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_10")
        blocked = self.engine.action("buy_intel", str(npc["district"]), {"npc_id": str(npc["id"]), "amount": 0})
        self.assertIn("不肯", blocked.message)
        self.engine.action("gift_money", str(npc["district"]), {"npc_id": str(npc["id"]), "amount": 10_000})
        player_cash_before = int(self.engine.state["player"]["cash"])
        npc_cash_before = int(next(row for row in self.engine.state["npcs"] if row["id"] == str(npc["id"]))["cash"])
        result = self.engine.action("buy_intel", str(npc["district"]), {"npc_id": str(npc["id"]), "amount": 0})
        npc_after = next(row for row in result.world_state["npcs"] if row["id"] == str(npc["id"]))
        self.assertLess(int(result.world_state["player"]["cash"]), player_cash_before)
        self.assertGreater(int(npc_after["cash"]), npc_cash_before)
        self.assertTrue(result.world_state["rumor_log"])
        self.assertGreater(int(npc_after["player_memory"]["intel_spend_total"]), 0)

    def test_large_gift_can_make_npc_follow_player(self) -> None:
        npc = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_10")
        result = self.engine.action("gift_money", str(npc["district"]), {"npc_id": str(npc["id"]), "amount": 20_000})
        npc_after = next(row for row in result.world_state["npcs"] if row["id"] == str(npc["id"]))
        self.assertTrue(npc_after["player_memory"]["follows_player"])
        self.assertEqual(next(card for card in result.world_state["npc_cards"] if card["id"] == str(npc["id"]))["relation_status"], "跟着你")

    def test_social_pair_score_blocks_elite_worker_casual_contact(self) -> None:
        boss = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_05")
        worker = next(
            row
            for row in self.engine.state["npcs"]
            if row["district"] == "工厂区" and row["role"] in {"工人", "临时工"} and row["id"] != boss["id"]
        )
        worker["subregion_id"] = boss["subregion_id"]
        score = self.engine._npc_social_pair_score(boss, worker, 36.0, 0.12)
        self.assertIsNone(score)

    def test_social_schedule_splits_factory_boss_worker_and_organizer_under_unrest(self) -> None:
        self.engine._apply_intel_packet(
            {
                "id": "factory_unrest_probe",
                "district": "工厂区",
                "source": "test rumor",
                "title": "工厂区工资风声",
                "line": "工厂区里都在传降薪和慢工，工棚口已经有人开始互相串联。",
                "body": "工厂区里都在传降薪和慢工，工棚口已经有人开始互相串联。",
                "tags": ["工厂", "工资", "传闻"],
                "scope": "district",
                "topic_kind": "labor",
                "goods_delta": {"煤": 0.04},
                "stocks_delta": {"龟甲船运": -0.03},
                "macro_delta": {"worker_unrest": 1.2},
                "family_delta": {"龟甲船坞": -0.04},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        self.engine.state["district_signals"]["工厂区"]["labor_heat"] = 0.82
        self.engine.state["district_signals"]["工厂区"]["gossip"] = 0.48
        self.engine.state["clock_minutes"] = 10 * 60 + 15
        self.engine._apply_clock_state()
        self.engine._refresh_derived_views()
        self.engine._apply_npc_schedule()
        boss = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_05")
        organizer = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_27")
        worker = next(row for row in self.engine.state["npcs"] if row["district"] == "工厂区" and row["role"] == "工人")
        self.assertEqual(boss["subregion_id"], "watermill_yard")
        self.assertEqual(worker["subregion_id"], str(worker.get("work_subregion_id", worker.get("subregion_id", ""))))
        self.assertEqual(organizer["subregion_id"], "stoneyard_workcamp")
        self.assertIn(boss["activity"], {"working", "watching"})
        self.assertEqual(worker["activity"], "working")
        self.assertEqual(organizer["activity"], "assembling")
        self.assertTrue(any(token in organizer["current_goal"] for token in ["工厂区工资风声", "工钱与班次", "去串联一圈"]))

    @unittest.skip("Specific reporter identity is no longer deterministic after quota-based social routing.")
    def test_social_schedule_limits_exchange_media_to_one_watcher_and_keeps_banker_working(self) -> None:
        self.engine.state["district_signals"]["交易所"]["gossip"] = 0.76
        self.engine.state["district_signals"]["交易所"]["trade_heat"] = 0.44
        self.engine.state["clock_minutes"] = 12 * 60
        self.engine._apply_clock_state()
        self.engine._apply_npc_schedule()
        reporter = next(row for row in self.engine.state["npcs"] if row["role"] == "记者")
        banker = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_16")
        self.assertEqual(reporter["subregion_id"], "church_graveyard")
        self.assertEqual(reporter["activity"], "watching")
        self.assertEqual(banker["subregion_id"], str(banker.get("work_subregion_id", banker.get("subregion_id", ""))))
        self.assertEqual(banker["activity"], "working")
        self.assertNotEqual(reporter["subregion_id"], banker["subregion_id"])

    def test_exchange_authority_roles_work_from_inner_tower(self) -> None:
        self.engine.state["clock_minutes"] = 10 * 60
        self.engine._apply_clock_state()
        self.engine._apply_npc_schedule()
        mayor = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_11")
        regulator = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_10")
        self.assertEqual(mayor["subregion_id"], "rune_tower")
        self.assertEqual(regulator["subregion_id"], "rune_tower")
        self.assertIn(mayor["activity"], {"working", "watching"})
        self.assertIn(regulator["activity"], {"working", "watching"})

    def test_home_period_keeps_residents_at_home_even_if_gossip_is_hot(self) -> None:
        resident = next(
            row
            for row in self.engine.state["npcs"]
            if row["role"] in {"临时工", "工人"} and row.get("class") in {"底层", "关键角色"}
        )
        resident_district = str(resident["district"])
        self.engine.state["district_signals"][resident_district]["gossip"] = 0.92
        self.engine.state["district_signals"][resident_district]["labor_heat"] = 0.88
        self.engine.state["clock_minutes"] = 22 * 60 + 10
        self.engine._apply_clock_state()
        self.engine._apply_npc_schedule()
        resident = next(row for row in self.engine.state["npcs"] if row["id"] == resident["id"])
        self.assertEqual(resident["activity"], "home")
        self.assertEqual(resident["subregion_id"], str(resident.get("home_subregion_id", resident.get("subregion_id", ""))))

    def test_social_override_caps_exchange_roamers_to_small_group(self) -> None:
        self.engine.state["district_signals"]["交易所"]["gossip"] = 0.88
        self.engine.state["district_signals"]["交易所"]["trade_heat"] = 0.82
        self.engine.state["clock_minutes"] = 12 * 60
        self.engine._apply_clock_state()
        self.engine._apply_npc_schedule()
        exchange_roamers = [
            row for row in self.engine.state["npcs"]
            if row["district"] == "交易所" and row["activity"] in {"watching", "assembling", "gathering"}
        ]
        self.assertLessEqual(len(exchange_roamers), 3)

    def test_social_target_prefers_trusted_contact_who_has_not_heard_hot_topic(self) -> None:
        self.engine._apply_intel_packet(
            {
                "id": "rumor_targeting_probe",
                "district": "宸ュ巶鍖?",
                "source": "test rumor",
                "title": "factory targeting rumor",
                "line": "Someone is pushing a wage rumor through the yard.",
                "body": "Someone is pushing a wage rumor through the yard.",
                "tags": ["rumor", "factory", "wage"],
                "scope": "district",
                "topic_kind": "labor",
                "goods_delta": {},
                "stocks_delta": {"榫熺敳鑸硅繍": -0.03},
                "macro_delta": {"worker_unrest": 1.1},
                "family_delta": {"榫熺敳鑸瑰潪": -0.04},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        topic_id = self.engine.snapshot()["topic_registry"][0]["id"]
        speaker = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_36")
        listener = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_23")
        speaker["prompt_profile"]["trusted_people"] = [listener["name"]]
        speaker["heard_topic_ids"] = [topic_id]
        listener["heard_topic_ids"] = []
        target_name = self.engine._npc_social_target_name(speaker, "organize", topic_id)
        self.assertEqual(target_name, listener["name"])

    def test_blocked_pairs_do_not_trigger_social_turns_even_if_close(self) -> None:
        boss = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_05")
        worker = next(
            row
            for row in self.engine.state["npcs"]
            if row["district"] == "工厂区" and row["role"] in {"工人", "临时工"} and row["id"] != boss["id"]
        )
        boss["x"] = 2200.0
        boss["y"] = 1100.0
        boss["subregion_id"] = "watermill_yard"
        worker["x"] = 2208.0
        worker["y"] = 1106.0
        worker["subregion_id"] = "watermill_yard"
        self.engine.state["npcs"] = [boss, worker]
        baseline = len(self.engine.state["local_broadcasts"])
        self.engine._run_agent_social_turns({}, allow_llm=False)
        self.assertEqual(len(self.engine.state["local_broadcasts"]), baseline)

    def test_conversation_registers_topic_memory_for_both_participants(self) -> None:
        self.engine._apply_intel_packet(
            {
                "id": "rumor_conversation_memory",
                "district": "宸ュ巶鍖?",
                "source": "test rumor",
                "title": "factory memory rumor",
                "line": "Workers are passing around another pay-cut whisper.",
                "body": "Workers are passing around another pay-cut whisper.",
                "tags": ["rumor", "factory", "wage"],
                "scope": "district",
                "topic_kind": "labor",
                "goods_delta": {},
                "stocks_delta": {"榫熺敳鑸硅繍": -0.02},
                "macro_delta": {"worker_unrest": 0.9},
                "family_delta": {"榫熺敳鑸瑰潪": -0.03},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        speaker = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_36")
        listener = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_23")
        speaker["subregion_id"] = "stoneyard_workcamp"
        listener["subregion_id"] = "stoneyard_workcamp"
        self.engine.conversation("npc_36", "npc_23", "测试串话", allow_llm=False)
        speaker_after = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_36")
        listener_after = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_23")
        topic_id = str(speaker_after.get("last_spoken_topic_id", ""))
        self.assertTrue(topic_id)
        self.assertIn(topic_id, speaker_after["heard_topic_ids"])
        self.assertIn(topic_id, listener_after["heard_topic_ids"])
        self.assertTrue(
            any(
                entry.get("kind") == "heard_topic" and entry.get("topic_id") == topic_id
                for entry in listener_after["local_memory_bank"]
            )
        )

    def test_local_hearing_does_not_cross_subregion_for_ordinary_speaker(self) -> None:
        self.engine._apply_intel_packet(
            {
                "id": "rumor_hearing_gate",
                "district": "璐皯琛?",
                "source": "test rumor",
                "title": "market hearing rumor",
                "line": "A stall whisper is moving through the market.",
                "body": "A stall whisper is moving through the market.",
                "tags": ["rumor", "market"],
                "scope": "district",
                "topic_kind": "public",
                "goods_delta": {"闈㈠寘": 0.03},
                "stocks_delta": {},
                "macro_delta": {"media_sentiment": 0.4},
                "family_delta": {},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        topic_id = self.engine.snapshot()["topic_registry"][0]["id"]
        speaker = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_06")
        listener = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_03")
        speaker["speech_lines"] = ["先把这话压低一点。"]
        speaker["last_spoken_topic_id"] = topic_id
        speaker["broadcast_intent"] = "low"
        speaker["emotion_delta"] = {"fear": 0, "greed": 0}
        speaker["subregion_id"] = "courtyard_garden"
        listener["subregion_id"] = "wild_path"
        listener["heard_topic_ids"] = []
        self.engine._apply_local_hearing(speaker)
        self.assertNotIn(topic_id, listener["heard_topic_ids"])

    def test_buy_and_sell_goods(self) -> None:
        buy = self.engine.action("buy_goods", "贫民街", {"good_name": "面包", "quantity": 1})
        self.assertIn("买入", buy.message)
        sell = self.engine.action("sell_goods", "贫民街", {"good_name": "面包", "quantity": 1})
        self.assertIn("卖出", sell.message)

    def test_end_day_produces_event_and_news(self) -> None:
        result = self.engine.end_day()
        self.assertGreaterEqual(result.world_state["day"], 2)
        self.assertTrue(result.world_state["pending_events"])
        self.assertTrue(result.world_state["global_news"])

    def test_conversation_updates_local_broadcasts(self) -> None:
        result = self.engine.conversation("npc_07", "npc_10", "试探")
        self.assertTrue(result.world_state["local_broadcasts"])
        speaker = next(n for n in result.world_state["npcs"] if n["id"] == "npc_07")
        self.assertTrue(speaker["speech_lines"])

    def test_task_accept_and_claim(self) -> None:
        accepted = self.engine.action("accept_task", "交易所", {"task_id": "task_egret_credit"})
        self.assertIn("接下", accepted.message)
        self.engine.action("gather_info", "工厂区", {})
        self.engine.action("gather_info", "工厂区", {})
        claimed = self.engine.action("claim_task", "交易所", {"task_id": "task_egret_credit"})
        self.assertIn("任务完成", claimed.message)
        self.assertIn("task_egret_credit", claimed.world_state["player"]["completed_tasks"])

    def test_probe_ai_returns_status(self) -> None:
        result = self.engine.probe_ai()
        self.assertIn("probe", result.world_state)
        self.assertIn("ok", result.world_state["probe"])

    def test_player_talk_generates_dialogue(self) -> None:
        result = self.engine.player_talk("npc_03", "贫民街")
        self.assertIn("搭了几句线", result.message)
        self.assertIn("last_dialogue", result.world_state)
        self.assertTrue(result.world_state["last_dialogue"]["body"])

    def test_player_talk_with_topic_and_approach_surfaces_truth_data(self) -> None:
        snapshot = self.engine.snapshot()
        topic = next(topic for topic in snapshot["talk_topics"] if topic.get("kind") in {"asset", "family", "company"})
        npc_id = str(topic.get("npc_ids", ["npc_10"])[0])
        result = self.engine.player_talk(
            npc_id,
            str(topic.get("district", "")),
            str(topic.get("id", "")),
            "friendly",
            "问风声",
        )
        dialogue = result.world_state["last_dialogue"]
        self.assertIn("truthfulness", dialogue)
        self.assertIn("confidence", dialogue)
        self.assertEqual(dialogue["topic_id"], topic.get("id", ""))
        self.assertEqual(dialogue["approach"], "friendly")
        self.assertTrue(dialogue["world_effects"])

    def test_ai_pulse_records_scene_observation(self) -> None:
        result = self.engine.ai_pulse(
            trigger="manual_scene",
            scene_observation={
                "current_district": "贫民街",
                "player_position": {"x": 220.0, "y": 250.0},
                "screenshot_b64": "ZmFrZV9wbmc=",
                "scene_context": {
                    "current_district": "贫民街",
                    "nearby_npcs": [{"name": "碎步"}],
                    "nearby_interactables": [{"title": "面包小摊"}],
                },
            },
        )
        self.assertEqual(result.world_state["scene_observation"]["current_district"], "贫民街")
        self.assertTrue(result.world_state["macro_summary"]["scene_director_note"])

    def test_gather_info_creates_rumor_and_intraday_move(self) -> None:
        result = self.engine.action("gather_info", "港口", {})
        after = result.world_state
        self.assertTrue(after["rumor_log"])
        self.assertTrue(after["player"]["rumors"])
        self.assertTrue(after["local_rumor"])
        self.assertTrue(after["topic_registry"])
        self.assertTrue(after["active_topics"])
        self.assertTrue(str(after["rumor_log"][0].get("topic_id", "")))
        self.assertTrue(
            any(abs(value) > 0.0 for value in after["market_pressure"]["goods"].values())
            or any(abs(value) > 0.0 for value in after["market_pressure"]["stocks"].values())
            or after["quick_hud"]["latest_rumor"]
        )

    def test_topic_registry_merges_repeated_rumors(self) -> None:
        packet = {
            "id": "rumor_test_supply",
            "district": "贫民街",
            "source": "测试风声",
            "title": "面包供给风声",
            "line": "海藻家族在市集悄悄囤货。",
            "body": "海藻家族在市集悄悄囤货。",
            "tags": ["传闻", "贫民街", "粮价"],
            "scope": "district",
            "topic_kind": "supply",
            "goods_delta": {"面包": 0.08},
            "stocks_delta": {},
            "macro_delta": {},
            "family_delta": {"海藻家族": 0.04},
        }
        self.engine._apply_intel_packet(packet, to_player=False, promote_news=False, intensity=1.0)
        self.engine._apply_intel_packet(packet, to_player=False, promote_news=False, intensity=0.6)
        snapshot = self.engine.snapshot()
        self.assertEqual(len(snapshot["topic_registry"]), 1)
        topic = snapshot["topic_registry"][0]
        self.assertEqual(topic["id"], "topic_supply_贫民街_面包")
        self.assertEqual(topic["mention_count"], 2)
        self.assertGreaterEqual(topic["spread_count"], 2)
        self.assertEqual(snapshot["rumor_log"][0]["topic_id"], topic["id"])
        self.assertTrue(snapshot["active_topics"])

    def test_npc_prompt_includes_explicit_topic_digest(self) -> None:
        self.engine._apply_intel_packet(
            {
                "id": "rumor_prompt_supply",
                "district": "贫民街",
                "source": "测试风声",
                "title": "面包供给风声",
                "line": "海藻家族在市集悄悄囤货。",
                "body": "海藻家族在市集悄悄囤货。",
                "tags": ["传闻", "贫民街", "粮价"],
                "scope": "district",
                "topic_kind": "supply",
                "goods_delta": {"面包": 0.08},
                "stocks_delta": {},
                "macro_delta": {},
                "family_delta": {"海藻家族": 0.04},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        snapshot = self.engine.snapshot()
        npc = next(n for n in snapshot["npcs"] if n["id"] == "npc_01")
        self.assertIn("显式议题=", npc["agent_prompt"])
        self.assertIn("面包的供给风声", npc["agent_prompt"])

    def test_seeded_norms_surface_in_snapshot_and_prompt(self) -> None:
        snapshot = self.engine.snapshot()
        self.assertTrue(snapshot["norm_registry"])
        self.assertTrue(snapshot["active_norms"])
        self.assertTrue(snapshot["quick_hud"]["norm_prompt"])
        self.assertTrue(snapshot["macro_summary"]["norms_brief"])
        npc = next(n for n in snapshot["npcs"] if n["id"] == "npc_01")
        self.assertIn("显式规范=", npc["agent_prompt"])
        self.assertIn("先保住口粮", snapshot["macro_summary"]["norms_brief"])

    def test_npc_topic_and_norm_actions_update_systems(self) -> None:
        self.engine._apply_intel_packet(
            {
                "id": "rumor_labor_norm",
                "district": "工厂区",
                "source": "测试风声",
                "title": "工厂工资风声",
                "line": "船坞总经理准备继续压工资线。",
                "body": "船坞总经理准备继续压工资线。",
                "tags": ["传闻", "工厂", "工资"],
                "scope": "district",
                "topic_kind": "labor",
                "goods_delta": {},
                "stocks_delta": {"龟甲船运": -0.05},
                "macro_delta": {"worker_unrest": 1.8},
                "family_delta": {"龟甲船坞": -0.04},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        topic_id = self.engine.snapshot()["topic_registry"][0]["id"]
        before_topic = next(topic for topic in self.engine.state["topic_registry"] if topic["id"] == topic_id)
        before_norm = next(norm for norm in self.engine.state["norm_registry"] if norm["text"] == "降薪不能忍")
        before_heat = float(before_topic["heat"])
        before_spread = int(before_topic["spread_count"])
        before_reinforce = int(before_norm["reinforce_count"])
        self.engine._apply_llm_npc_updates(
            [
                {
                    "id": "npc_36",
                    "line": "这口气不能再忍，得把人先聚起来。",
                    "stance": "激进",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "amplify", "topic_id": topic_id, "intensity": 0.78, "note": "把情绪往上拱"},
                    "norm_action": {"mode": "reinforce", "text": "降薪不能忍", "intensity": 0.74, "note": "把不满变成共识"},
                }
            ]
        )
        snapshot = self.engine.snapshot()
        topic = next(topic for topic in snapshot["topic_registry"] if topic["id"] == topic_id)
        norm = next(norm for norm in snapshot["norm_registry"] if norm["text"] == "降薪不能忍")
        spin = snapshot["npc_spin_map"]["npc_36"]
        self.assertGreater(float(topic["heat"]), before_heat)
        self.assertGreater(int(topic["spread_count"]), before_spread)
        self.assertEqual(topic["last_action"], "amplify")
        self.assertGreater(int(norm["reinforce_count"]), before_reinforce)
        self.assertEqual(spin["topic_action"]["mode"], "amplify")
        self.assertEqual(spin["norm_action"]["mode"], "reinforce")

    def test_collective_actions_emerge_from_labor_topic(self) -> None:
        self.engine._apply_intel_packet(
            {
                "id": "rumor_collective_seed",
                "district": "工厂区",
                "source": "测试风声",
                "title": "工厂工资风声",
                "line": "船坞总经理准备把班次压得更狠，工人私下已经在串。",
                "body": "船坞总经理准备把班次压得更狠，工人私下已经在串。",
                "tags": ["传闻", "工厂", "工资"],
                "scope": "district",
                "topic_kind": "labor",
                "goods_delta": {},
                "stocks_delta": {"龟甲船运": -0.06},
                "macro_delta": {"worker_unrest": 2.2},
                "family_delta": {"龟甲船坞": -0.05},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        snapshot = self.engine.snapshot()
        self.assertTrue(snapshot["collective_action_registry"])
        self.assertTrue(snapshot["active_collective_actions"])
        action = snapshot["collective_action_registry"][0]
        self.assertIn(action["kind"], {"strike", "meeting"})
        self.assertEqual(action["district"], "工厂区")
        self.assertTrue(snapshot["quick_hud"]["collective_prompt"])
        npc = next(n for n in snapshot["npcs"] if n["id"] == "npc_27")
        self.assertIn("显式集体行动=", npc["agent_prompt"])

    def test_collective_actions_progress_from_organize_to_attend(self) -> None:
        self.engine._apply_intel_packet(
            {
                "id": "rumor_collective_progress",
                "district": "工厂区",
                "source": "测试风声",
                "title": "工厂工资风声",
                "line": "船坞里已经有人在约晚上碰头，准备把降薪的事摊开。",
                "body": "船坞里已经有人在约晚上碰头，准备把降薪的事摊开。",
                "tags": ["传闻", "工厂", "工资"],
                "scope": "district",
                "topic_kind": "labor",
                "goods_delta": {},
                "stocks_delta": {"龟甲船运": -0.05},
                "macro_delta": {"worker_unrest": 1.9},
                "family_delta": {"龟甲船坞": -0.04},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        seed_snapshot = self.engine.snapshot()
        topic_id = seed_snapshot["topic_registry"][0]["id"]
        action_id = seed_snapshot["collective_action_registry"][0]["id"]
        workers = [
            str(npc.get("id", ""))
            for npc in self.engine.state["npcs"]
            if str(npc.get("district", "")) == "工厂区" and str(npc.get("role", "")) in {"工人", "临时工", "工会领袖"}
        ][:2]
        self.assertGreaterEqual(len(workers), 2)
        self.engine._apply_llm_npc_updates(
            [
                {
                    "id": "npc_36",
                    "line": "先把人拢起来，今晚别各回各家。",
                    "stance": "激进",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "amplify", "topic_id": topic_id, "intensity": 0.78, "note": "让更多人听见"},
                    "norm_action": {"mode": "reinforce", "text": "降薪不能忍", "intensity": 0.72, "note": "把不满变成共识"},
                    "collective_action": {"mode": "organize", "action_id": action_id, "kind": "strike", "intensity": 0.84, "note": "先定一个碰头口"},
                },
                {
                    "id": workers[0],
                    "line": "我去，今晚算我一个。",
                    "stance": "抱团",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "share", "topic_id": topic_id, "intensity": 0.62, "note": "传给工友"},
                    "norm_action": {"mode": "reinforce", "text": "降薪不能忍", "intensity": 0.6, "note": "跟上口风"},
                    "collective_action": {"mode": "commit", "action_id": action_id, "kind": "strike", "intensity": 0.74, "note": "先答应到"},
                },
                {
                    "id": workers[1],
                    "line": "别光说，我现在就去门口等。",
                    "stance": "激进",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "share", "topic_id": topic_id, "intensity": 0.6, "note": "把人带过去"},
                    "norm_action": {"mode": "reinforce", "text": "降薪不能忍", "intensity": 0.58, "note": "顶住"},
                    "collective_action": {"mode": "attend", "action_id": action_id, "kind": "strike", "intensity": 0.82, "note": "直接到场"},
                },
            ]
        )
        snapshot = self.engine.snapshot()
        action = next(row for row in snapshot["collective_action_registry"] if row["id"] == action_id)
        spin = snapshot["npc_spin_map"]["npc_36"]
        self.assertGreaterEqual(int(action["support_count"]), 3)
        self.assertGreaterEqual(int(action["commit_count"]), 3)
        self.assertGreaterEqual(int(action["attendee_count"]), 1)
        self.assertIn(action["stage"], {"committing", "active"})
        self.assertEqual(spin["collective_action"]["mode"], "organize")

    def test_collective_actions_surface_target_and_response_metadata(self) -> None:
        self.engine._apply_intel_packet(
            {
                "id": "rumor_collective_metadata",
                "district": "工厂区",
                "source": "测试风声",
                "title": "工厂工资风声",
                "line": "工头压班的消息已经把厂区气压顶高了。",
                "body": "工头压班的消息已经把厂区气压顶高了。",
                "tags": ["传闻", "工厂", "工资"],
                "scope": "district",
                "topic_kind": "labor",
                "goods_delta": {},
                "stocks_delta": {"龟甲船运": -0.05},
                "macro_delta": {"worker_unrest": 2.0},
                "family_delta": {"龟甲船坞": -0.04},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        snapshot = self.engine.snapshot()
        action = snapshot["active_collective_actions"][0]
        self.assertTrue(action["target_location_title"])
        self.assertTrue(action["target_subregion_name"])
        self.assertGreater(float(action["target_x"]), 0.0)
        self.assertGreater(float(action["target_y"]), 0.0)
        self.assertIn(action["response_mode"], {"observe", "suppress", "negotiate"})
        self.assertTrue(snapshot["macro_summary"]["collective_brief"])

    def test_collective_schedule_moves_participants_and_responders(self) -> None:
        self.engine._apply_intel_packet(
            {
                "id": "rumor_collective_schedule",
                "district": "工厂区",
                "source": "测试风声",
                "title": "工厂工资风声",
                "line": "船坞里已经开始串人，白天就准备堵到值台前。",
                "body": "船坞里已经开始串人，白天就准备堵到值台前。",
                "tags": ["传闻", "工厂", "工资"],
                "scope": "district",
                "topic_kind": "labor",
                "goods_delta": {},
                "stocks_delta": {"龟甲船运": -0.05},
                "macro_delta": {"worker_unrest": 2.1},
                "family_delta": {"龟甲船坞": -0.05},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        seed_snapshot = self.engine.snapshot()
        topic_id = seed_snapshot["topic_registry"][0]["id"]
        action_id = seed_snapshot["collective_action_registry"][0]["id"]
        workers = [
            str(npc.get("id", ""))
            for npc in self.engine.state["npcs"]
            if str(npc.get("district", "")) == "工厂区" and str(npc.get("role", "")) in {"工人", "临时工", "工会领袖"}
        ][:2]
        self.engine._apply_llm_npc_updates(
            [
                {
                    "id": "npc_36",
                    "line": "白天就堵到值台前，别让他们当没看见。",
                    "stance": "激进",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "amplify", "topic_id": topic_id, "intensity": 0.78, "note": "往外拱"},
                    "norm_action": {"mode": "reinforce", "text": "降薪不能忍", "intensity": 0.72, "note": "拧成一股"},
                    "collective_action": {"mode": "organize", "action_id": action_id, "kind": "strike", "intensity": 0.84, "note": "先把人带过去"},
                },
                {
                    "id": workers[0],
                    "line": "我跟着过去。",
                    "stance": "抱团",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "share", "topic_id": topic_id, "intensity": 0.62, "note": "传给工友"},
                    "norm_action": {"mode": "reinforce", "text": "降薪不能忍", "intensity": 0.6, "note": "跟上"},
                    "collective_action": {"mode": "commit", "action_id": action_id, "kind": "strike", "intensity": 0.74, "note": "先答应"},
                },
                {
                    "id": workers[1],
                    "line": "我现在就去。",
                    "stance": "激进",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "share", "topic_id": topic_id, "intensity": 0.6, "note": "继续带"},
                    "norm_action": {"mode": "reinforce", "text": "降薪不能忍", "intensity": 0.58, "note": "顶住"},
                    "collective_action": {"mode": "attend", "action_id": action_id, "kind": "strike", "intensity": 0.82, "note": "到场"},
                },
            ]
        )
        self.engine.state["clock_minutes"] = 9 * 60 + 45
        self.engine._apply_clock_state()
        self.engine._apply_npc_schedule()
        snapshot = self.engine.snapshot()
        action = next(row for row in snapshot["collective_action_registry"] if row["id"] == action_id)
        organizer = next(npc for npc in snapshot["npcs"] if npc["id"] == "npc_36")
        self.assertIn(organizer["activity"], {"assembling", "protesting", "meeting"})
        self.assertLess(abs(float(organizer["x"]) - float(action["target_x"])), 120.0)
        self.assertLess(abs(float(organizer["y"]) - float(action["target_y"])), 120.0)
        self.assertTrue(action["response_actor_ids"])
        responder_id = str(action["response_actor_ids"][0])
        responder = next(npc for npc in snapshot["npcs"] if npc["id"] == responder_id)
        self.assertIn(responder["activity"], {"responding", "negotiating", "watching"})
        self.assertLess(abs(float(responder["x"]) - float(action["response_target_x"])), 140.0)
        self.assertLess(abs(float(responder["y"]) - float(action["response_target_y"])), 140.0)

    def test_collective_intervention_can_trigger_concession(self) -> None:
        self.engine._apply_intel_packet(
            {
                "id": "rumor_collective_concede",
                "district": "工厂区",
                "source": "测试风声",
                "title": "工厂工资风声",
                "line": "工友已经准备白天去堵值台，场子里都在等谁先松口。",
                "body": "工友已经准备白天去堵值台，场子里都在等谁先松口。",
                "tags": ["传闻", "工厂", "工资"],
                "scope": "district",
                "topic_kind": "labor",
                "goods_delta": {},
                "stocks_delta": {"龟甲船运": -0.05},
                "macro_delta": {"worker_unrest": 2.0},
                "family_delta": {"龟甲船坞": -0.05},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        seed_snapshot = self.engine.snapshot()
        topic_id = seed_snapshot["topic_registry"][0]["id"]
        action_id = seed_snapshot["collective_action_registry"][0]["id"]
        workers = [
            str(npc.get("id", ""))
            for npc in self.engine.state["npcs"]
            if str(npc.get("district", "")) == "工厂区" and str(npc.get("role", "")) in {"工人", "临时工", "工会领袖"}
        ][:2]
        self.engine._apply_llm_npc_updates(
            [
                {
                    "id": "npc_36",
                    "line": "今天就去把人拢到值台前。",
                    "stance": "激进",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "amplify", "topic_id": topic_id, "intensity": 0.8, "note": "继续往上拱"},
                    "norm_action": {"mode": "reinforce", "text": "降薪不能忍", "intensity": 0.72, "note": "拧成一股"},
                    "collective_action": {"mode": "organize", "action_id": action_id, "kind": "strike", "intensity": 0.86, "note": "把人带过去"},
                },
                {
                    "id": workers[0],
                    "line": "我先答应，到了时间就去。",
                    "stance": "抱团",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "share", "topic_id": topic_id, "intensity": 0.66, "note": "传给工友"},
                    "norm_action": {"mode": "reinforce", "text": "降薪不能忍", "intensity": 0.62, "note": "跟上"},
                    "collective_action": {"mode": "commit", "action_id": action_id, "kind": "strike", "intensity": 0.74, "note": "先答应"},
                },
                {
                    "id": workers[1],
                    "line": "我现在就去门口。",
                    "stance": "激进",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "share", "topic_id": topic_id, "intensity": 0.62, "note": "继续带"},
                    "norm_action": {"mode": "reinforce", "text": "降薪不能忍", "intensity": 0.58, "note": "顶住"},
                    "collective_action": {"mode": "attend", "action_id": action_id, "kind": "strike", "intensity": 0.82, "note": "到场"},
                },
            ]
        )
        self.engine.state["clock_minutes"] = 9 * 60 + 45
        self.engine._apply_clock_state()
        self.engine._apply_npc_schedule()
        before = next(row for row in self.engine.snapshot()["collective_action_registry"] if row["id"] == action_id)
        before_threshold = float(before["effective_turnout_threshold"])
        result = self.engine.action("collective_intervene", "工厂区", {"action_id": action_id, "mode": "mediate"})
        action = next(row for row in result.world_state["collective_action_registry"] if row["id"] == action_id)
        self.assertLess(float(action["effective_turnout_threshold"]), before_threshold)
        self.assertEqual(action["resolution_kind"], "conceded")
        self.assertTrue(result.world_state["collective_outcomes"])

    def test_collective_intervention_can_escalate_suppression(self) -> None:
        self.engine._apply_intel_packet(
            {
                "id": "rumor_collective_escalate",
                "district": "工厂区",
                "source": "测试风声",
                "title": "工厂工资风声",
                "line": "有人想去值台前闹一场，但现在还是零散串联。",
                "body": "有人想去值台前闹一场，但现在还是零散串联。",
                "tags": ["传闻", "工厂", "工资"],
                "scope": "district",
                "topic_kind": "labor",
                "goods_delta": {},
                "stocks_delta": {"龟甲船运": -0.04},
                "macro_delta": {"worker_unrest": 1.8},
                "family_delta": {"龟甲船坞": -0.04},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        seed_snapshot = self.engine.snapshot()
        topic_id = seed_snapshot["topic_registry"][0]["id"]
        action_id = seed_snapshot["collective_action_registry"][0]["id"]
        self.engine._apply_llm_npc_updates(
            [
                {
                    "id": "npc_36",
                    "line": "先把风放出去，看看谁敢先站出来。",
                    "stance": "激进",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "amplify", "topic_id": topic_id, "intensity": 0.72, "note": "先点火"},
                    "norm_action": {"mode": "reinforce", "text": "降薪不能忍", "intensity": 0.66, "note": "试探口风"},
                    "collective_action": {"mode": "organize", "action_id": action_id, "kind": "strike", "intensity": 0.8, "note": "先拢人"},
                }
            ]
        )
        self.engine.state["clock_minutes"] = 10 * 60 + 40
        self.engine._apply_clock_state()
        self.engine._apply_npc_schedule()
        before_unrest = int(self.engine.state["macro"]["worker_unrest"])
        result = self.engine.action("collective_intervene", "工厂区", {"action_id": action_id, "mode": "suppress"})
        action = next(row for row in result.world_state["collective_action_registry"] if row["id"] == action_id)
        self.assertEqual(action["resolution_kind"], "escalated")
        self.assertGreater(int(result.world_state["macro"]["worker_unrest"]), before_unrest)

    def test_collective_action_can_fizzle_after_window(self) -> None:
        self.engine._apply_intel_packet(
            {
                "id": "rumor_collective_fizzle",
                "district": "工厂区",
                "source": "测试风声",
                "title": "工厂工资风声",
                "line": "有人放话说要去堵值台，但一整天都没多少人真到场。",
                "body": "有人放话说要去堵值台，但一整天都没多少人真到场。",
                "tags": ["传闻", "工厂", "工资"],
                "scope": "district",
                "topic_kind": "labor",
                "goods_delta": {},
                "stocks_delta": {"龟甲船运": -0.04},
                "macro_delta": {"worker_unrest": 1.6},
                "family_delta": {"龟甲船坞": -0.03},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        snapshot = self.engine.snapshot()
        action_id = snapshot["collective_action_registry"][0]["id"]
        self.engine.state["clock_minutes"] = 18 * 60 + 10
        self.engine._apply_clock_state()
        self.engine._refresh_derived_views()
        action = next(row for row in self.engine.state["collective_action_registry"] if row["id"] == action_id)
        self.assertEqual(action["resolution_kind"], "fizzled")
        self.assertTrue(self.engine.state["collective_outcomes"])

    def test_collective_concession_queues_and_applies_settlement_followup(self) -> None:
        company = next(row for row in self.engine.state["companies"] if row["id"] == "company_blackstone")
        district = str(company["district"])
        stock_name = str(company["stock_name"])
        family_name = str(company["family_owner"])
        self.engine._apply_intel_packet(
            {
                "id": "rumor_collective_settlement",
                "district": district,
                "source": "test rumor",
                "title": "factory wage rumor",
                "line": "Workers say the yard gate finally has enough people to push for a concession.",
                "body": "Workers say the yard gate finally has enough people to push for a concession.",
                "tags": ["rumor", "factory", "wage"],
                "scope": "district",
                "topic_kind": "labor",
                "goods_delta": {},
                "stocks_delta": {stock_name: -0.05},
                "macro_delta": {"worker_unrest": 2.0},
                "family_delta": {family_name: -0.05},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        seed_snapshot = self.engine.snapshot()
        topic_id = seed_snapshot["topic_registry"][0]["id"]
        action_id = seed_snapshot["collective_action_registry"][0]["id"]
        workers = [str(npc.get("id", "")) for npc in self.engine.state["npcs"] if str(npc.get("district", "")) == district and str(npc.get("id", "")) != "npc_36"][:2]
        self.engine._apply_llm_npc_updates(
            [
                {
                    "id": "npc_36",
                    "line": "Bring them to the gate first, then force the talk.",
                    "stance": "militant",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "amplify", "topic_id": topic_id, "intensity": 0.82, "note": "push harder"},
                    "norm_action": {"mode": "reinforce", "text": "pay cuts cannot stand", "intensity": 0.72, "note": "lock the line"},
                    "collective_action": {"mode": "organize", "action_id": action_id, "kind": "strike", "intensity": 0.88, "note": "organize the gate"},
                },
                {
                    "id": workers[0],
                    "line": "I will commit first and show up on time.",
                    "stance": "solidarity",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "share", "topic_id": topic_id, "intensity": 0.68, "note": "share to coworkers"},
                    "norm_action": {"mode": "reinforce", "text": "pay cuts cannot stand", "intensity": 0.62, "note": "commit first"},
                    "collective_action": {"mode": "commit", "action_id": action_id, "kind": "strike", "intensity": 0.76, "note": "commit first"},
                },
                {
                    "id": workers[1],
                    "line": "I am going there now and will stay on the line.",
                    "stance": "militant",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "share", "topic_id": topic_id, "intensity": 0.64, "note": "bring another worker"},
                    "norm_action": {"mode": "reinforce", "text": "pay cuts cannot stand", "intensity": 0.58, "note": "hold the line"},
                    "collective_action": {"mode": "attend", "action_id": action_id, "kind": "strike", "intensity": 0.84, "note": "show up"},
                },
            ]
        )
        self.engine.state["clock_minutes"] = 9 * 60 + 45
        self.engine._apply_clock_state()
        self.engine._apply_npc_schedule()
        result = self.engine.action("collective_intervene", district, {"action_id": action_id, "mode": "mediate"})
        self.assertEqual(result.world_state["collective_outcomes"][0]["resolution_kind"], "conceded")
        followup = next(row for row in result.world_state["collective_followups"] if row["kind"] == "settlement")
        self.assertEqual(followup["source_action_id"], action_id)
        wage_before = float(company["wage_level"])
        inventory_before = int(company["inventory"])
        self.engine._advance_clock(120)
        company_after = next(row for row in self.engine.state["companies"] if row["id"] == "company_blackstone")
        self.assertGreater(float(company_after["wage_level"]), wage_before)
        self.assertGreater(int(company_after["inventory"]), inventory_before)

    def test_collective_escalation_spawns_secondary_topic_and_followup_action(self) -> None:
        company = next(row for row in self.engine.state["companies"] if row["id"] == "company_blackstone")
        district = str(company["district"])
        stock_name = str(company["stock_name"])
        family_name = str(company["family_owner"])
        self.engine._apply_intel_packet(
            {
                "id": "rumor_collective_aftershock",
                "district": district,
                "source": "test rumor",
                "title": "factory crackdown rumor",
                "line": "People are gathering at the yard gate, and the atmosphere is turning heavy.",
                "body": "People are gathering at the yard gate, and the atmosphere is turning heavy.",
                "tags": ["rumor", "factory", "wage"],
                "scope": "district",
                "topic_kind": "labor",
                "goods_delta": {},
                "stocks_delta": {stock_name: -0.04},
                "macro_delta": {"worker_unrest": 1.8},
                "family_delta": {family_name: -0.04},
            },
            to_player=False,
            promote_news=False,
            intensity=1.0,
        )
        seed_snapshot = self.engine.snapshot()
        topic_id = seed_snapshot["topic_registry"][0]["id"]
        action_id = seed_snapshot["collective_action_registry"][0]["id"]
        self.engine._apply_llm_npc_updates(
            [
                {
                    "id": "npc_36",
                    "line": "Push the crowd to the gate and see who dares to stand up.",
                    "stance": "militant",
                    "market_tilt": "neutral",
                    "topic_action": {"mode": "amplify", "topic_id": topic_id, "intensity": 0.74, "note": "light the fuse"},
                    "norm_action": {"mode": "reinforce", "text": "pay cuts cannot stand", "intensity": 0.66, "note": "test the wind"},
                    "collective_action": {"mode": "organize", "action_id": action_id, "kind": "strike", "intensity": 0.82, "note": "gather them"},
                }
            ]
        )
        self.engine.state["clock_minutes"] = 10 * 60 + 40
        self.engine._apply_clock_state()
        self.engine._apply_npc_schedule()
        result = self.engine.action("collective_intervene", district, {"action_id": action_id, "mode": "suppress"})
        self.assertEqual(result.world_state["collective_outcomes"][0]["resolution_kind"], "escalated")
        followup = next(row for row in result.world_state["collective_followups"] if row["kind"] == "crackdown")
        self.assertEqual(followup["source_action_id"], action_id)
        self.engine._advance_clock(60)
        self.engine._refresh_derived_views()
        followup_after = next(row for row in self.engine.state["collective_followups"] if row["id"] == followup["id"])
        self.assertTrue(str(followup_after.get("secondary_topic_id", "")))
        self.assertTrue(str(followup_after.get("followup_action_id", "")))
        followup_action = next(row for row in self.engine.state["collective_action_registry"] if row["id"] == followup_after["followup_action_id"])
        self.assertEqual(followup_action["parent_action_id"], action_id)
        self.assertGreaterEqual(int(followup_action["escalation_level"]), 1)

    def test_player_collective_profile_surfaces_in_hud_and_family_moves(self) -> None:
        baseline_move = next(row for row in self.engine.snapshot()["family_moves"] if row["id"] == "wolf")
        district = str(next(row for row in self.engine.state["companies"] if row["id"] == "company_blackstone")["district"])
        action = {"id": "collective_profile_probe", "label": "profile probe", "district": district}
        self.engine._record_player_collective_intervention(action, "support")
        self.engine._record_player_collective_intervention(action, "support")
        self.engine._record_player_collective_intervention(action, "support")
        self.engine._refresh_derived_views()
        profile = self.engine.state["task_summary"]["player_collective_profile"]
        self.assertEqual(profile["dominant_mode"], "support")
        self.assertGreaterEqual(int(profile["consecutive_count"]), 3)
        self.assertTrue(self.engine.state["quick_hud"]["player_collective_stance"])
        self.assertTrue(self.engine.state["quick_hud"]["reputation_flash"])
        move_after = next(row for row in self.engine.state["family_moves"] if row["id"] == "wolf")
        self.assertEqual(move_after["name"], baseline_move["name"])

    def test_end_day_prefers_matching_event_conditions(self) -> None:
        self.engine.state["macro"]["worker_unrest"] = 82
        self.engine.state["macro"]["economy_heat"] = 45
        result = self.engine.end_day()
        event_id = result.world_state["pending_events"][0]["id"]
        self.assertIn(event_id, {"port_strike", "street_unrest", "mine_rumor"})


    def test_snapshot_contains_clock_fields(self) -> None:
        snapshot = self.engine.snapshot()
        self.assertIn("clock_label", snapshot["macro_summary"])
        self.assertIn("time_period", snapshot["macro_summary"])
        self.assertIn("light_level", snapshot["macro_summary"])
        self.assertTrue(snapshot["district_topic"])

    def test_npcs_have_home_and_activity(self) -> None:
        snapshot = self.engine.snapshot()
        npc = snapshot["npcs"][0]
        self.assertIn("home_x", npc)
        self.assertIn("home_y", npc)
        self.assertIn("activity", npc)
        self.assertIn("home_state", npc)
        self.assertIn("indoor_activity", npc)
        self.assertIn("house_states", snapshot)
        first_house = next(iter(snapshot["house_states"].values()))
        self.assertIn("primary_activity", first_house)
        self.assertIn("secondary_activity", first_house)

    def test_rest_action_improves_credit(self) -> None:
        before = self.engine.snapshot()["player"]["credit"]
        result = self.engine.action("rest", "贫民街", {"house_title": "龟壳小屋"})
        self.assertTrue(result.message)
        self.assertGreaterEqual(result.world_state["player"]["credit"], before)

    def test_home_search_changes_resources(self) -> None:
        result = self.engine.action("search_home", "贫民街", {"house_title": "龟壳小屋"})
        self.assertTrue(result.message)
        player = result.world_state["player"]
        self.assertTrue(
            player["cash"] >= 30 or player["goods_inventory"].get("罐头", 0) >= 1 or len(player["rumors"]) >= 1
        )


    def test_company_pressure_generates_company_topic(self) -> None:
        company = self.engine.state["companies"][0]
        company["financing_pressure"] = 82
        company["order_pressure"] = 74
        self.engine._refresh_derived_views()
        topics = self.engine.snapshot()["talk_topics"]
        self.assertTrue(any(topic.get("kind") == "company" for topic in topics))

    def test_ai_pulse_generates_institution_actions(self) -> None:
        company = self.engine.state["companies"][0]
        company["financing_pressure"] = 84
        result = self.engine.ai_pulse(trigger="manual_scene")
        self.assertTrue(result.world_state["institution_actions"])
        self.assertTrue(result.world_state["quick_hud"]["institution_flash"])

    def test_family_move_exposes_operation_metadata(self) -> None:
        snapshot = self.engine.snapshot()
        move = snapshot["family_moves"][0]
        self.assertIn("pressure_score", move)
        self.assertIn("controlled_company_ids", move)
        self.assertIn("operation_style", move)
        self.assertIn("capital_posture", move)

    def test_personal_pressure_generates_livelihood_topic(self) -> None:
        npc = self.engine.state["npcs"][0]
        npc["debt"] = 64
        npc["hunger"] = 72
        self.engine._refresh_derived_views()
        topics = self.engine.snapshot()["talk_topics"]
        self.assertTrue(any(topic.get("kind") in {"livelihood", "ration"} for topic in topics))

    def test_npc_cards_surface_personal_summary(self) -> None:
        snapshot = self.engine.snapshot()
        card = snapshot["npc_cards"][0]
        self.assertIn("personal_summary", card)
        self.assertIn("economic_pressure", card)
        self.assertIn("truthfulness", card)
        self.assertIn("institution_note", card)

    def test_payroll_delay_pushes_worker_pressure(self) -> None:
        company = self.engine.state["companies"][0]
        npc = next(npc for npc in self.engine.state["npcs"] if str(npc.get("company_id", "")) == str(company.get("id", "")))
        before_debt = int(npc.get("debt", 0))
        company["payroll_delay"] = 55
        self.engine._run_livelihood_tick("end_day")
        self.assertGreaterEqual(int(npc.get("debt", 0)), before_debt)
        self.assertIn("late_pay", npc.get("memory_tags", []))

    def test_institution_action_publishes_layered_news_and_topic(self) -> None:
        company = self.engine.state["companies"][0]
        company["financing_pressure"] = 86
        result = self.engine.ai_pulse(trigger="manual_scene")
        snapshot = result.world_state
        self.assertTrue(any(topic.get("kind") == "institution" for topic in snapshot["talk_topics"]))
        self.assertTrue(snapshot["local_rumor"])
        self.assertTrue(snapshot["city_news"])
        lead = snapshot["institution_actions"][0]
        self.assertIn("headline", lead)
        self.assertIn("news_body", lead)
        self.assertIn("effect_score", lead)

    def test_company_state_surfaces_funding_and_workforce_state(self) -> None:
        snapshot = self.engine.snapshot()
        state = snapshot["company_states"][0]
        self.assertIn("payroll_delay", state)
        self.assertIn("funding_state", state)
        self.assertIn("workforce_mood", state)

    def test_ai_pulse_applies_llm_batch_brief(self) -> None:
        self.engine.ark._client = object()

        def fake_pulse_brief(_payload: dict[str, object]) -> dict[str, object]:
            return {
                "pulse_summary": "交易所在热，港口在忍。",
                "market_note": "海藻食业被人护着，码头工资却在拖。",
                "scene_focus": "钟楼下的人都在看牌价和你。",
                "npc_updates": [
                    {"id": "npc_01", "line": "砖牙：工牌还挂着，但工钱已经慢了。", "stance": "谨慎"},
                    {"id": "npc_02", "line": "灰鳍：港口嘴上稳，手却在抖。", "stance": "现实"},
                ],
                "family_updates": [
                    {"name": "海藻家族", "public_line": "海藻家族嘴上说保供，手上先护粮票。", "hidden_line": "海藻家族在等别人先慌。", "focus": "护住海藻食业"},
                ],
                "company_updates": [
                    {"id": "company_blue_tide", "headline": "海藻食业表面稳着，底下在拖码头工钱。", "worker_note": "港口工人开始算欠账。", "risk_note": "融资口还没彻底补上。"},
                ],
            }

        def fake_npc_spin(payload: dict[str, object]) -> dict[str, object]:
            npc = payload.get("npc", {})
            npc_id = str(npc.get("id", "npc"))
            if npc_id == "npc_01":
                return {"stance": "谨慎", "truthfulness": 0.5, "market_tilt": "neutral", "lines": ["砖牙：工牌还挂着，但工钱已经慢了。"]}
            return {"stance": "补单", "truthfulness": 0.5, "market_tilt": "neutral", "lines": [f"{npc_id}：补单。"]}

        def fake_family_briefing(payload: dict[str, object]) -> dict[str, object]:
            family = payload.get("family", {})
            family_name = str(family.get("name", "家族"))
            if family_name == "海藻资本":
                return {"public_line": "海藻资本嘴上说保供，手上先护粮票。", "hidden_line": "海藻资本在等别人先慌。", "focus": "护住海藻重工", "signal": "support"}
            return {"public_line": f"{family_name}：补单。", "hidden_line": "补单。", "focus": "补单", "signal": "steady"}

        def fake_company_briefing(payload: dict[str, object]) -> dict[str, object]:
            company = payload.get("company", {})
            company_id = str(company.get("id", "company"))
            if company_id == "company_blue_tide":
                return {"headline": "海藻食业表面稳着，底下在拖码头工钱。", "worker_note": "港口工人开始算欠账。", "risk_note": "融资口还没彻底补上。", "signal": "stress"}
            return {"headline": f"{company_id}：补单。", "worker_note": "补单。", "risk_note": "补单。", "signal": "steady"}

        self.engine.ark.generate_pulse_brief = fake_pulse_brief  # type: ignore[method-assign]
        self.engine.ark.generate_npc_spin = fake_npc_spin  # type: ignore[method-assign]
        self.engine.ark.generate_family_briefing = fake_family_briefing  # type: ignore[method-assign]
        self.engine.ark.generate_company_briefing = fake_company_briefing  # type: ignore[method-assign]
        result = self.engine.ai_pulse(trigger="manual_scene")
        snapshot = result.world_state
        self.assertEqual(snapshot["llm_pulse_summary"], "交易所在热，港口在忍。")
        self.assertEqual(snapshot["llm_market_note"], "海藻食业被人护着，码头工资却在拖。")
        self.assertTrue(snapshot["npc_spin_map"]["npc_01"]["line"].startswith("砖牙"))
        self.assertEqual(snapshot["family_briefings"]["海藻资本"]["focus"], "护住海藻重工")
        self.assertIn("拖码头工钱", snapshot["company_briefings"]["company_blue_tide"]["headline"])
        self.assertEqual(snapshot["quick_hud"]["ai_focus"], "交易所在热，港口在忍。")
        self.assertTrue(any(card.get("llm_source") == "llm" for card in snapshot["npc_cards"]))

    def test_scheduled_pulse_reuses_cached_scene_observation(self) -> None:
        seen_screens: list[str] = []

        def fake_pulse_brief(payload: dict[str, object]) -> dict[str, object]:
            observation = payload.get("scene_observation", {})
            if isinstance(observation, dict):
                seen_screens.append(str(observation.get("screenshot_b64", "")))
            return {
                "pulse_summary": "城里还在互相试底。",
                "market_note": "市场先听风，再动价。",
                "scene_focus": "旧截图也还够看清街口的局。",
                "npc_updates": [],
                "family_updates": [],
                "company_updates": [],
            }

        self.engine.ark.generate_pulse_brief = fake_pulse_brief  # type: ignore[method-assign]
        self.engine.ai_pulse(
            trigger="manual_scene",
            scene_observation={
                "current_district": "港口",
                "player_position": {"x": 10.0, "y": 20.0},
                "screenshot_b64": "cached_image",
                "scene_context": {"nearby_npcs": [{"name": "旧锚"}]},
            },
        )
        self.engine.ai_pulse(trigger="scheduled")
        self.assertGreaterEqual(len(seen_screens), 2)
        self.assertEqual(seen_screens[-1], "cached_image")

    def test_player_talk_persists_relationship_memory(self) -> None:
        result = self.engine.player_talk("npc_03", "贫民街", "", "friendly", "问账本")
        npc = next(npc for npc in result.world_state["npcs"] if npc["id"] == "npc_03")
        memory = npc["player_memory"]
        self.assertGreaterEqual(memory["talk_count"], 1)
        self.assertEqual(memory["last_approach"], "friendly")
        self.assertEqual(memory["last_intent"], "问账本")
        self.assertTrue(npc["relationship_memory"])
        card = next(card for card in result.world_state["npc_cards"] if card["id"] == "npc_03")
        self.assertIn("你问过", card["memory_summary"])
        self.assertIn("relation_status", card)

    def test_repeated_hardball_reduces_truth_profile(self) -> None:
        baseline = self.engine._truth_metrics_for_topic(
            self.engine._find_npc("npc_10"),
            self.engine.snapshot()["talk_topics"][0],
            "cautious",
            "问风声",
        )
        self.engine.player_talk("npc_10", "交易所", "", "hardball", "问家族")
        self.engine.player_talk("npc_10", "交易所", "", "hardball", "问谁在放风")
        npc = self.engine._find_npc("npc_10")
        topic = self.engine._resolve_talk_topic(npc, "", "交易所")
        pressured = self.engine._truth_metrics_for_topic(npc, topic, "hardball", "问谁在放风")
        self.assertLessEqual(pressured["truthfulness"], baseline["truthfulness"])
        self.assertGreater(float(npc["player_memory"]["pressure_from_player"]), 0.0)

    def test_llm_pulse_payload_contains_relationship_memory(self) -> None:
        captured_payloads: list[dict[str, object]] = []

        def fake_pulse_brief(payload: dict[str, object]) -> dict[str, object]:
            captured_payloads.append(payload)
            return {
                "pulse_summary": "城里开始记住谁在问价。",
                "market_note": "问得勤的人，慢慢会被人认出来。",
                "scene_focus": "几双眼都记住了你的壳。",
                "npc_updates": [],
                "family_updates": [],
                "company_updates": [],
            }

        self.engine.player_talk("npc_03", "贫民街", "", "friendly", "问账本")
        self.engine.ark.generate_pulse_brief = fake_pulse_brief  # type: ignore[method-assign]
        self.engine.ai_pulse(trigger="manual_scene")
        self.assertTrue(captured_payloads)
        npc_rows = captured_payloads[-1]["npcs"]
        self.assertIsInstance(npc_rows, list)
        npc_03 = next(row for row in npc_rows if isinstance(row, dict) and row.get("id") == "npc_03")
        self.assertIn("memory_summary", npc_03)
        self.assertTrue(str(npc_03["memory_summary"]))

    def test_llm_backfills_missing_npcs_families_and_companies(self) -> None:
        self.engine.ark._client = object()

        def fake_pulse_brief(_payload: dict[str, object]) -> dict[str, object]:
            return {
                "pulse_summary": "先给一部分人口风，剩下的人补单。",
                "market_note": "盘口先听声，再慢慢挪。",
                "scene_focus": "这轮先看谁漏了。",
                "npc_updates": [{"id": "npc_01", "line": "npc_01：我先开口。", "stance": "谨慎", "market_tilt": "neutral"}],
                "family_updates": [{"name": "海藻家族", "public_line": "海藻先放保供话。", "hidden_line": "海藻还在后面等。", "focus": "海藻食业", "signal": "support"}],
                "company_updates": [{"id": "company_blue_tide", "headline": "蓝潮先稳住门面。", "worker_note": "码头工人先盯着。", "risk_note": "融资口子没完全开。", "signal": "steady"}],
            }

        def fake_npc_spin(payload: dict[str, object]) -> dict[str, object]:
            npc = payload.get("npc", {})
            npc_id = str(npc.get("id", "npc"))
            return {
                "stance": "补单",
                "truthfulness": 0.5,
                "market_tilt": "neutral",
                "lines": [f"{npc_id}：这句是补出来的。"] ,
            }

        def fake_family_briefing(payload: dict[str, object]) -> dict[str, object]:
            family = payload.get("family", {})
            family_name = str(family.get("name", "家族"))
            return {
                "public_line": f"{family_name} 补了一句公开口风。",
                "hidden_line": f"{family_name} 也补了一句暗线。",
                "focus": "补齐家族",
                "signal": "steady",
            }

        def fake_company_briefing(payload: dict[str, object]) -> dict[str, object]:
            company = payload.get("company", {})
            company_id = str(company.get("id", "company"))
            return {
                "headline": f"{company_id} 也补了一句公司摘要。",
                "worker_note": "工人也被补上了。",
                "risk_note": "风险提示也补上了。",
                "signal": "steady",
            }

        self.engine.ark.generate_pulse_brief = fake_pulse_brief  # type: ignore[method-assign]
        self.engine.ark.generate_npc_spin = fake_npc_spin  # type: ignore[method-assign]
        self.engine.ark.generate_family_briefing = fake_family_briefing  # type: ignore[method-assign]
        self.engine.ark.generate_company_briefing = fake_company_briefing  # type: ignore[method-assign]
        snapshot = self.engine.ai_pulse(trigger="manual_scene").world_state
        self.assertTrue(all(row.get("source") == "llm" for row in snapshot["npc_spin_map"].values()))
        self.assertTrue(all(row.get("source") == "llm" for row in snapshot["family_briefings"].values()))
        self.assertTrue(all(row.get("source") == "llm" for row in snapshot["company_briefings"].values()))

    def test_llm_signals_surface_in_histories_and_market_pressure(self) -> None:
        self.engine.ark._client = object()
        before_stock = float(self.engine.state["market_pressure"]["stocks"]["海藻重工"])

        def fake_pulse_brief(_payload: dict[str, object]) -> dict[str, object]:
            return {
                "pulse_summary": "有人在稳盘，有人在咬牙。",
                "market_note": "海藻嘴上稳，下面其实紧。",
                "scene_focus": "码头和交易所都在盯盘。",
                "npc_updates": [{"id": "npc_01", "line": "npc_01：我看这票要先往下压。", "stance": "冷眼", "market_tilt": "bearish"}],
                "family_updates": [{"name": "海藻资本", "public_line": "海藻出来护盘。", "hidden_line": "海藻先保重工。", "focus": "海藻重工", "signal": "support"}],
                "company_updates": [{"id": "company_blue_tide", "headline": "海藻重工门面还撑着。", "worker_note": "工人嘴上不说，心里开始算账。", "risk_note": "融资口子紧。", "signal": "stress"}],
            }

        def fake_npc_spin(payload: dict[str, object]) -> dict[str, object]:
            npc = payload.get("npc", {})
            npc_id = str(npc.get("id", "npc"))
            market_tilt = "bearish" if npc_id == "npc_01" else "neutral"
            return {"stance": "补单", "truthfulness": 0.5, "market_tilt": market_tilt, "lines": [f"{npc_id}：补单。"]}

        def fake_family_briefing(_payload: dict[str, object]) -> dict[str, object]:
            return {"public_line": "补家族公开口风。", "hidden_line": "补家族暗线。", "focus": "补齐", "signal": "steady"}

        def fake_company_briefing(_payload: dict[str, object]) -> dict[str, object]:
            return {"headline": "补公司摘要。", "worker_note": "补工人感受。", "risk_note": "补风险。", "signal": "steady"}

        self.engine.ark.generate_pulse_brief = fake_pulse_brief  # type: ignore[method-assign]
        self.engine.ark.generate_npc_spin = fake_npc_spin  # type: ignore[method-assign]
        self.engine.ark.generate_family_briefing = fake_family_briefing  # type: ignore[method-assign]
        self.engine.ark.generate_company_briefing = fake_company_briefing  # type: ignore[method-assign]
        snapshot = self.engine.ai_pulse(trigger="manual_scene").world_state
        after_stock = float(snapshot["market_pressure"]["stocks"]["海藻重工"])
        self.assertNotEqual(before_stock, after_stock)
        company_state = next(state for state in snapshot["company_states"] if state["id"] == "company_blue_tide")
        family_move = next(move for move in snapshot["family_moves"] if move["name"] == "海藻资本")
        npc_card = next(card for card in snapshot["npc_cards"] if card["id"] == "npc_01")
        self.assertTrue(company_state["recent_briefs"])
        self.assertTrue(family_move["recent_briefs"])
        self.assertTrue(npc_card["brief_history"])
        self.assertEqual(npc_card["llm_market_tilt"], "bearish")

    def test_one_pulse_calls_each_entity_individually(self) -> None:
        self.engine.ark._client = object()
        npc_calls: list[str] = []
        family_calls: list[str] = []
        company_calls: list[str] = []

        def fake_pulse_brief(_payload: dict[str, object]) -> dict[str, object]:
            return {
                "pulse_summary": "这一分钟先总览。",
                "market_note": "总览之后逐个过人。",
                "scene_focus": "所有实体都要单独过一遍。",
                "npc_updates": [],
                "family_updates": [],
                "company_updates": [],
            }

        def fake_npc_spin(payload: dict[str, object]) -> dict[str, object]:
            npc = payload.get("npc", {})
            npc_id = str(npc.get("id", ""))
            npc_calls.append(npc_id)
            return {"stance": "逐个", "truthfulness": 0.5, "market_tilt": "neutral", "lines": [f"{npc_id}：逐个更新。"]}

        def fake_family_briefing(payload: dict[str, object]) -> dict[str, object]:
            family = payload.get("family", {})
            family_name = str(family.get("name", ""))
            family_calls.append(family_name)
            return {"public_line": f"{family_name}：逐个更新。", "hidden_line": "暗线也逐个。", "focus": "逐个", "signal": "steady"}

        def fake_company_briefing(payload: dict[str, object]) -> dict[str, object]:
            company = payload.get("company", {})
            company_id = str(company.get("id", ""))
            company_calls.append(company_id)
            return {"headline": f"{company_id}：逐个更新。", "worker_note": "工人也逐个。", "risk_note": "风险也逐个。", "signal": "steady"}

        self.engine.ark.generate_pulse_brief = fake_pulse_brief  # type: ignore[method-assign]
        self.engine.ark.generate_npc_spin = fake_npc_spin  # type: ignore[method-assign]
        self.engine.ark.generate_family_briefing = fake_family_briefing  # type: ignore[method-assign]
        self.engine.ark.generate_company_briefing = fake_company_briefing  # type: ignore[method-assign]
        self.engine.ai_pulse(trigger="manual_scene")
        self.assertEqual(len(set(npc_calls)), len(self.engine.state["npcs"]))
        self.assertEqual(len(set(family_calls)), len(self.engine.state["families"]))
        self.assertEqual(len(set(company_calls)), len(self.engine.state["companies"]))

    def test_second_pulse_skips_distant_low_heat_npcs(self) -> None:
        self.engine.ark._client = object()
        npc_calls: list[str] = []

        hot_npc = self.engine._find_npc("npc_01")
        cool_npc = self.engine._find_npc("npc_34")
        hot_npc["debt"] = 88
        hot_npc["hunger"] = 70
        cool_npc["debt"] = 0
        cool_npc["hunger"] = 0
        cool_npc["anxiety"] = 5.0

        def fake_pulse_brief(_payload: dict[str, object]) -> dict[str, object]:
            return {
                "pulse_summary": "这一分钟按热度分层刷新。",
                "market_note": "近处和高热先说，远处慢一点。",
                "scene_focus": "不是所有人都每分钟开口。",
                "npc_updates": [],
                "family_updates": [],
                "company_updates": [],
            }

        def fake_npc_spin(payload: dict[str, object]) -> dict[str, object]:
            npc = payload.get("npc", {})
            npc_id = str(npc.get("id", ""))
            npc_calls.append(npc_id)
            return {"stance": "分层", "truthfulness": 0.5, "market_tilt": "neutral", "lines": [f"{npc_id}：按档位刷新。"]}

        def fake_family_briefing(_payload: dict[str, object]) -> dict[str, object]:
            return {"public_line": "家族照常。", "hidden_line": "家族照常。", "focus": "照常", "signal": "steady"}

        def fake_company_briefing(_payload: dict[str, object]) -> dict[str, object]:
            return {"headline": "公司照常。", "worker_note": "公司照常。", "risk_note": "公司照常。", "signal": "steady"}

        self.engine.ark.generate_pulse_brief = fake_pulse_brief  # type: ignore[method-assign]
        self.engine.ark.generate_npc_spin = fake_npc_spin  # type: ignore[method-assign]
        self.engine.ark.generate_family_briefing = fake_family_briefing  # type: ignore[method-assign]
        self.engine.ark.generate_company_briefing = fake_company_briefing  # type: ignore[method-assign]

        self.engine.ai_pulse(
            trigger="manual_scene",
            scene_observation={
                "current_district": str(hot_npc.get("district", "")),
                "player_position": {"x": float(hot_npc.get("x", 0.0)), "y": float(hot_npc.get("y", 0.0))},
                "scene_context": {"nearby_npcs": [{"id": "npc_01", "name": hot_npc.get("name", "")}]},
            },
        )
        npc_calls.clear()
        self.engine.ai_pulse(
            trigger="scheduled",
            scene_observation={
                "current_district": str(hot_npc.get("district", "")),
                "player_position": {"x": float(hot_npc.get("x", 0.0)), "y": float(hot_npc.get("y", 0.0))},
                "scene_context": {"nearby_npcs": [{"id": "npc_01", "name": hot_npc.get("name", "")}]},
            },
        )
        self.assertIn("npc_01", npc_calls)
        self.assertNotIn("npc_34", npc_calls)

    def test_only_summary_and_hot_or_nearby_npcs_keep_screenshot(self) -> None:
        self.engine.ark._client = object()
        pulse_shots: list[str] = []
        npc_shots: dict[str, str] = {}
        family_shots: list[str] = []
        company_shots: list[str] = []

        hot_npc = self.engine._find_npc("npc_01")
        cool_npc = self.engine._find_npc("npc_34")
        hot_npc["debt"] = 92
        hot_npc["hunger"] = 75
        cool_npc["debt"] = 0
        cool_npc["hunger"] = 0
        cool_npc["anxiety"] = 2.0

        def fake_pulse_brief(payload: dict[str, object]) -> dict[str, object]:
            scene_observation = payload.get("scene_observation", {})
            pulse_shots.append(str(scene_observation.get("screenshot_b64", "")))
            return {
                "pulse_summary": "总览带图。",
                "market_note": "图片只给高热和近身角色。",
                "scene_focus": "远处低热角色改成纯文本。",
                "npc_updates": [],
                "family_updates": [],
                "company_updates": [],
            }

        def fake_npc_spin(payload: dict[str, object]) -> dict[str, object]:
            npc = payload.get("npc", {})
            scene_observation = payload.get("scene_observation", {})
            npc_shots[str(npc.get("id", ""))] = str(scene_observation.get("screenshot_b64", ""))
            return {"stance": "分层", "truthfulness": 0.5, "market_tilt": "neutral", "lines": ["分层刷新"]}

        def fake_family_briefing(payload: dict[str, object]) -> dict[str, object]:
            scene_observation = payload.get("scene_observation", {})
            family_shots.append(str(scene_observation.get("screenshot_b64", "")))
            return {"public_line": "家族纯文本", "hidden_line": "家族纯文本", "focus": "纯文本", "signal": "steady"}

        def fake_company_briefing(payload: dict[str, object]) -> dict[str, object]:
            scene_observation = payload.get("scene_observation", {})
            company_shots.append(str(scene_observation.get("screenshot_b64", "")))
            return {"headline": "公司纯文本", "worker_note": "公司纯文本", "risk_note": "公司纯文本", "signal": "steady"}

        self.engine.ark.generate_pulse_brief = fake_pulse_brief  # type: ignore[method-assign]
        self.engine.ark.generate_npc_spin = fake_npc_spin  # type: ignore[method-assign]
        self.engine.ark.generate_family_briefing = fake_family_briefing  # type: ignore[method-assign]
        self.engine.ark.generate_company_briefing = fake_company_briefing  # type: ignore[method-assign]

        self.engine.ai_pulse(
            trigger="manual_scene",
            scene_observation={
                "current_district": str(hot_npc.get("district", "")),
                "player_position": {"x": float(hot_npc.get("x", 0.0)), "y": float(hot_npc.get("y", 0.0))},
                "scene_context": {"nearby_npcs": [{"id": "npc_01", "name": hot_npc.get("name", "")}]},
                "screenshot_b64": "demo-image",
            },
        )

        self.assertEqual(pulse_shots, ["demo-image"])
        self.assertEqual(npc_shots.get("npc_01"), "demo-image")
        self.assertTrue(family_shots)
        self.assertTrue(company_shots)
        self.assertTrue(all(not shot for shot in family_shots))
        self.assertTrue(all(not shot for shot in company_shots))

    def test_scheduled_scene_pulse_stays_rule_based_and_drops_screenshot(self) -> None:
        self.engine.ark._client = object()
        pulse_calls: list[dict[str, object]] = []
        social_llm_calls: list[dict[str, object]] = []

        def fake_pulse_brief(payload: dict[str, object]) -> dict[str, object]:
            pulse_calls.append(payload)
            return {
                "pulse_summary": "不该被调用",
                "market_note": "不该被调用",
                "scene_focus": "不该被调用",
                "npc_updates": [],
                "family_updates": [],
                "company_updates": [],
            }

        def fake_dialogue_turn(payload: dict[str, object]) -> dict[str, object]:
            social_llm_calls.append(payload)
            return {"lines": ["……", "不该被调用"], "stance": "谨慎", "truthfulness": 0.5}

        self.engine.ark.generate_pulse_brief = fake_pulse_brief  # type: ignore[method-assign]
        self.engine.ark.generate_dialogue_turn = fake_dialogue_turn  # type: ignore[method-assign]
        self.engine._full_scheduled_llm_mode = lambda: False  # type: ignore[method-assign]

        self.engine.ai_pulse(
            trigger="scheduled_scene",
            scene_observation={
                "current_district": "交易所",
                "player_position": {"x": 100.0, "y": 100.0},
                "scene_context": {"nearby_npcs": []},
                "screenshot_b64": "should-not-pass",
            },
        )

        self.assertEqual(pulse_calls, [])
        self.assertEqual(social_llm_calls, [])
        self.assertEqual(str(self.engine.state.get("scene_observation", {}).get("screenshot_b64", "")), "should-not-pass")

    def test_player_talk_uses_live_scene_and_spreads_to_bystanders(self) -> None:
        self.engine.ark._client = object()
        captured_dialogues: list[dict[str, object]] = []

        def fake_dialogue_turn(payload: dict[str, object]) -> dict[str, object]:
            captured_dialogues.append(payload)
            return {
                "lines": ["这城里谁先说真话，谁就先吃亏。", "账房那边先紧了，别在明面上追问。"],
                "stance": "谨慎",
                "truthfulness": 0.74,
                "revealed_topic_ids": [str(payload.get("topic", {}).get("id", ""))],
            }

        self.engine.ark.generate_dialogue_turn = fake_dialogue_turn  # type: ignore[method-assign]
        result = self.engine.player_talk(
            "npc_03",
            "贫民街",
            "",
            "friendly",
            "问口粮",
            scene_observation={
                "current_district": "贫民街",
                "player_position": {"x": 220.0, "y": 250.0},
                "screenshot_b64": "live-shot",
                "scene_context": {
                    "nearby_npcs": [{"id": "npc_06", "name": "旁听甲"}, {"id": "npc_08", "name": "旁听乙"}],
                    "nearby_interactables": [],
                },
            },
        )
        self.assertTrue(captured_dialogues)
        self.assertEqual(captured_dialogues[-1]["scene_observation"]["screenshot_b64"], "live-shot")
        self.assertGreaterEqual(int(result.world_state["last_dialogue"].get("heard_by", 0)), 1)
        witness = next(npc for npc in result.world_state["npcs"] if npc["id"] == "npc_06")
        self.assertTrue(any(str(tag).startswith("heard_player:npc_03") for tag in witness["memory_tags"]))

    def test_conversation_uses_live_scene_and_pushes_rumor(self) -> None:
        self.engine.ark._client = object()
        captured_dialogues: list[dict[str, object]] = []

        def fake_dialogue_turn(payload: dict[str, object]) -> dict[str, object]:
            captured_dialogues.append(payload)
            return {
                "lines": ["港口账面没表面那么稳。", "你少说两句，昨晚已经有人在借桥钱了。"],
                "stance": "现实",
                "truthfulness": 0.68,
                "revealed_topic_ids": [str(payload.get("topic", {}).get("id", ""))],
            }

        self.engine.ark.generate_dialogue_turn = fake_dialogue_turn  # type: ignore[method-assign]
        result = self.engine.conversation(
            "npc_02",
            "npc_04",
            "街头搭话",
            scene_observation={
                "current_district": "港口",
                "player_position": {"x": 10.0, "y": 20.0},
                "screenshot_b64": "dock-shot",
                "scene_context": {"nearby_npcs": [{"id": "npc_02"}, {"id": "npc_04"}]},
            },
        )
        self.assertTrue(captured_dialogues)
        self.assertEqual(captured_dialogues[-1]["scene_observation"]["screenshot_b64"], "dock-shot")
        self.assertTrue(result.world_state["rumor_log"])

    def test_promoted_intel_news_prefers_ai_copy(self) -> None:
        self.engine.ark._client = object()

        def fake_news_copy(payload: dict[str, object]) -> dict[str, object]:
            self.assertEqual(payload.get("source_line", ""), "账面开始发紧")
            return {
                "title": "报馆把风声写上了头条",
                "body": "街上的私语已经越过摊位，开始压到盘口。",
                "tags": ["媒体", "风声"],
                "tone": "cold",
            }

        self.engine.ark.generate_news_copy = fake_news_copy  # type: ignore[method-assign]
        self.engine._apply_intel_packet(
            {
                "title": "交易所风声",
                "body": "账面开始发紧",
                "line": "账面开始发紧",
                "district": "交易所",
                "scope": "city",
                "tags": ["媒体", "金融"],
                "goods_delta": {},
                "stocks_delta": {"珊瑚金控": 0.08},
                "macro_delta": {},
                "family_delta": {},
            },
            to_player=False,
            promote_news=True,
            intensity=1.0,
        )
        self.assertEqual(self.engine.state["global_news"][0]["title"], "报馆把风声写上了头条")


    def test_favorability_register_changes_with_money_and_attitude_by_role(self) -> None:
        banker = next(row for row in self.engine.state["npcs"] if row["id"] == "npc_16")
        organizer = next(row for row in self.engine.state["npcs"] if row["role"] == "工会领袖")

        banker["player_relation"] = 10
        banker["player_trust"] = 76.0
        banker_memory = banker["player_memory"]
        banker_memory.update(
            {
                "talk_count": 8,
                "friendly_count": 4,
                "hardball_count": 0,
                "pressure_from_player": 0.0,
                "cash_gift_total": 30_000,
                "bought_over": True,
                "follows_player": False,
            }
        )
        banker_state = self.engine._npc_favorability_state(banker)
        self.assertIn(str(banker_state.get("speech_register", "")), {"deferential", "warm", "slick", "bought"})
        self.assertGreater(float(banker_state.get("disclosure_willingness", 0.0)), 0.55)

        organizer["player_relation"] = -6
        organizer["player_trust"] = 18.0
        organizer_memory = organizer["player_memory"]
        organizer_memory.update(
            {
                "talk_count": 6,
                "friendly_count": 0,
                "hardball_count": 5,
                "pressure_from_player": 1.3,
                "cash_gift_total": 0,
                "bought_over": False,
                "follows_player": False,
            }
        )
        organizer_state = self.engine._npc_favorability_state(organizer)
        self.assertIn(str(organizer_state.get("speech_register", "")), {"hostile", "sullen", "guarded"})
        self.assertGreater(float(organizer_state.get("resentment", 0.0)), float(organizer_state.get("respect", 0.0)))

    def test_player_stock_trade_updates_tape_market_cap_and_holder_registry(self) -> None:
        result = self.engine.action("buy_stock", "交易所", {"stock_name": "海藻重工", "quantity": 12})
        snapshot = result.world_state
        stock = next(row for row in snapshot["stocks"] if row["name"] == "海藻重工")
        self.assertTrue(snapshot["stock_trade_tape"])
        self.assertEqual(snapshot["stock_trade_tape"][0]["stock_name"], "海藻重工")
        self.assertEqual(int(snapshot["stock_trade_tape"][0]["quantity"]), 12)
        self.assertEqual(int(stock["market_cap"]), int(stock["issued_shares"]) * int(stock["current_price"]))
        holders = snapshot["stock_holder_registry"]["海藻重工"]
        self.assertTrue(any(row["holder_id"] == "player" and int(row["shares"]) >= 12 for row in holders))

    def test_social_schedule_keeps_ordinary_worker_on_the_job_without_extreme_heat(self) -> None:
        worker = next(row for row in self.engine.state["npcs"] if row["district"] == "工厂区" and row["role"] == "工人")
        self.engine.state["district_signals"]["工厂区"]["labor_heat"] = 0.24
        self.engine.state["district_signals"]["工厂区"]["gossip"] = 0.18
        self.engine.state["clock_minutes"] = 10 * 60 + 20
        self.engine._apply_clock_state()
        self.engine._apply_npc_schedule()
        self.assertEqual(worker["activity"], "working")
        self.assertEqual(worker["subregion_id"], str(worker.get("work_subregion_id", worker.get("subregion_id", ""))))

    def test_residences_are_distributed_and_exposed_on_npc_cards(self) -> None:
        snapshot = self.engine.snapshot()
        house_states = snapshot["house_states"]
        self.assertGreaterEqual(len(house_states), 12)
        for district in snapshot["districts"]:
            district_name = district["name"]
            homes = {
                str(npc.get("home_building_id", npc.get("home_id", "")))
                for npc in snapshot["npcs"]
                if str(npc.get("district", "")) == district_name
            }
            self.assertGreaterEqual(len(homes), 2)
        sample_card = snapshot["npc_cards"][0]
        self.assertIn("home_building_id", sample_card)
        self.assertIn("home_subregion_id", sample_card)
        self.assertIn("home_mode", sample_card)
        self.assertIn("home_slot", sample_card)
        self.assertIn("schedule_anchor_type", sample_card)

    def test_population_bias_summary_is_built_for_city_and_districts(self) -> None:
        snapshot = self.engine.snapshot()
        population_bias = snapshot["population_bias"]
        self.assertIn("citywide", population_bias)
        self.assertIn("districts", population_bias)
        self.assertTrue(population_bias["citywide"]["social_band_distribution"])
        self.assertIn("工厂区", population_bias["districts"])
        self.assertIn("top_norms", population_bias["districts"]["工厂区"])

    def test_player_talk_populates_render_fields_and_latency(self) -> None:
        self.engine.ark.generate_dialogue_turn = lambda payload: {  # type: ignore[method-assign]
            "lines": [str(payload.get("player_input", "")) or "……", "消息在扩散，但我只说一半。"],
            "stance": "谨慎",
            "truthfulness": 0.61,
            "_meta_model": "stub-model",
        }
        result = self.engine.player_talk("npc_01", "贫民街", player_input="你知道谁在抛售吗？")
        dialogue = result.world_state["last_dialogue"]
        self.assertEqual(dialogue["render_lines"][0], "你知道谁在抛售吗？")
        self.assertIn("消息在扩散，但我只说一半。", dialogue["render_body"])
        self.assertIn("latency_ms", dialogue)
        self.assertIn(dialogue["response_state"], {"llm", "fallback_rule"})
        self.assertEqual(dialogue["model"], "stub-model")

    def test_exchange_media_watchers_are_limited_to_one(self) -> None:
        district = "\u4ea4\u6613\u6240"
        banker_title = "\u9996\u5e2d\u64cd\u76d8\u624b"
        self.engine.state["district_signals"][district]["gossip"] = 0.76
        self.engine.state["district_signals"][district]["trade_heat"] = 0.44
        self.engine.state["clock_minutes"] = 12 * 60
        self.engine._apply_clock_state()
        self.engine._apply_npc_schedule()
        watchers = [
            row
            for row in self.engine.state["npcs"]
            if row["district"] == district
            and row["activity"] == "watching"
            and str(row.get("social_band", self.engine._npc_social_band(row))) == "media"
        ]
        banker = next(row for row in self.engine.state["npcs"] if row["title"] == banker_title)
        self.assertEqual(len(watchers), 1)
        self.assertEqual(watchers[0]["subregion_id"], "church_graveyard")
        self.assertEqual(banker["subregion_id"], str(banker.get("work_subregion_id", banker.get("subregion_id", ""))))
        self.assertEqual(banker["activity"], "working")

    def test_exchange_social_hotspots_never_exceed_two_people(self) -> None:
        district = "\u4ea4\u6613\u6240"
        self.engine.state["district_signals"][district]["gossip"] = 0.88
        self.engine.state["district_signals"][district]["trade_heat"] = 0.82
        self.engine.state["clock_minutes"] = 12 * 60
        self.engine._apply_clock_state()
        self.engine._apply_npc_schedule()
        roamers = [
            row
            for row in self.engine.state["npcs"]
            if row["district"] == district and row["activity"] in {"watching", "assembling", "gathering"}
        ]
        self.assertLessEqual(len(roamers), 3)
        hotspot_counts: dict[str, int] = {}
        for row in roamers:
            subregion_id = str(row.get("subregion_id", ""))
            hotspot_counts[subregion_id] = hotspot_counts.get(subregion_id, 0) + 1
        self.assertTrue(hotspot_counts)
        self.assertTrue(all(count <= 2 for count in hotspot_counts.values()))

if __name__ == "__main__":
    unittest.main()
