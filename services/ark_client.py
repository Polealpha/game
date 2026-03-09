from __future__ import annotations

import json
import os
import re
import sys
from typing import Any

try:
    from openai import OpenAI
except Exception:  # pragma: no cover
    OpenAI = None


HARDCODED_ARK_API_KEY = "521e4c18-b3f9-4b54-af94-1f404328f300"
FORCED_ARK_MODEL = "doubao-seed-1-6-flash-250828"
REPLY_LIMIT_SUFFIX = " 每次回复小于100字。"
ANTI_PLACEHOLDER_SUFFIX = " 不要复述 schema_hint 里的示例占位词，不要输出“玩家台词”“NPC台词”“立场”“topic_id”“信息不足”“未知”这类占位内容。"
THINKING_DISABLED_BODY = {"thinking": {"type": "disabled"}}
DEFAULT_ARK_MODEL_CANDIDATES = [
    FORCED_ARK_MODEL,
    "doubao-seed-2-0-lite-250821",
    "doubao-seed-2-0-pro-250821",
    "doubao-seed-1-6-vision-250815",
    "doubao-1-5-vision-pro-250328",
    "doubao-1-5-vision-lite-250315",
    "doubao-seed-1-6-251015",
    "doubao-seed-1-6-flash-250715",
    "doubao-seed-1-6-lite-250615",
]


class ArkClient:
    def __init__(self) -> None:
        self.api_key = HARDCODED_ARK_API_KEY
        raw_endpoint_id = os.getenv("ARK_ENDPOINT_ID", "").strip()
        self.endpoint_id = "" if raw_endpoint_id == self.api_key else raw_endpoint_id
        self.model_id = os.getenv("ARK_MODEL_ID", FORCED_ARK_MODEL).strip() or FORCED_ARK_MODEL
        self.model_label = os.getenv("ARK_MODEL_LABEL", self.model_id).strip() or self.model_id
        self.base_url = os.getenv("ARK_BASE_URL", "https://ark.cn-beijing.volces.com/api/v3")
        self.timeout_seconds = float(os.getenv("ARK_TIMEOUT_SECONDS", "8").strip() or "8")
        self._client = None
        disable_for_unittest = "unittest" in sys.modules and os.getenv("ARK_ENABLE_IN_TESTS", "0") != "1"
        if self.api_key and OpenAI is not None and not disable_for_unittest:
            self._client = OpenAI(api_key=self.api_key, base_url=self.base_url, timeout=self.timeout_seconds)

    @property
    def enabled(self) -> bool:
        return self._client is not None

    def generate_dialogue_turn(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        scene_observation = payload.get("scene_observation", {})
        return self._request_json(
            task_type="dialogue_turn",
            schema_hint='{"lines":["玩家台词","NPC台词"],"stance":"立场","truthfulness":0.0,"revealed_topic_ids":["topic_id"]}',
            system_prompt=(
                "你是《壳与市场》的角色对话引擎。"
                "必须只输出简体中文 JSON，不得输出英文句子、解释、思维过程、Markdown。"
                "禁止编造输入之外的价格、资产变动、政策结果或世界事件。"
                "如果身份资料和记忆不足，就根据提供的职业、家族、街区、饥饿、负债、舆论压力谨慎回答。"
            ),
            task_prompt=(
                "根据角色身份、独立记忆、立场、工具规则、当前截图和玩家话语，生成一轮对话。"
                "如果 player_input 不为空，必须把它原样作为玩家台词。"
                "NPC 必须结合自己的身份和最近记忆直接回答，不要空话。"
                "只返回 JSON。"
            ),
            state_prompt={
                "speaker": payload.get("speaker", {}),
                "listener": payload.get("listener", {}),
                "speaker_agent": payload.get("speaker_agent", {}),
                "listener_agent": payload.get("listener_agent", {}),
                "district": payload.get("district", ""),
                "trigger": payload.get("trigger", ""),
                "player_input": payload.get("player_input", ""),
                "topic": payload.get("topic", {}),
                "approach": payload.get("approach", "cautious"),
                "intent": payload.get("intent", ""),
                "truth_profile": payload.get("truth_profile", {}),
                "relationship_memory": payload.get("relationship_memory", {}),
                "scene_context": scene_observation.get("scene_context", {}),
            },
            screenshot_b64=scene_observation.get("screenshot_b64", ""),
        )

    def generate_news_copy(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        scene_observation = payload.get("scene_observation", {})
        return self._request_json(
            task_type="news_copy",
            schema_hint='{"title":"标题","body":"正文","tags":["标签"],"tone":"语气"}',
            system_prompt=(
                "你是《壳与市场》的城内新闻编辑。"
                "必须只输出简体中文 JSON。"
                "只能包装输入里已经存在的事实，不得虚构市场结果、余额变化或不存在的事件。"
            ),
            task_prompt="把提供的事件、宏观状态、市场变化写成一条短新闻。只返回 JSON。",
            state_prompt={
                "event_name": payload.get("event_name", ""),
                "district": payload.get("district", ""),
                "macro": payload.get("macro", {}),
                "stocks": payload.get("stocks", []),
                "source_line": payload.get("source_line", ""),
                "source_body": payload.get("source_body", ""),
                "tags": payload.get("tags", []),
                "goods_delta": payload.get("goods_delta", {}),
                "stocks_delta": payload.get("stocks_delta", {}),
                "family_delta": payload.get("family_delta", {}),
                "scene_context": scene_observation.get("scene_context", {}),
            },
            screenshot_b64=scene_observation.get("screenshot_b64", ""),
        )

    def generate_scene_read(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        observation = payload.get("scene_observation", {})
        return self._request_json(
            task_type="scene_read",
            schema_hint='{"director_note":"导演旁白","headline_title":"标题","headline_body":"摘要"}',
            system_prompt=(
                "你是《壳与市场》的场景导演。"
                "必须只输出简体中文 JSON。"
                "只能总结画面气氛、人物紧张感、交易和舆论温度，不得编造新结果。"
            ),
            task_prompt="根据截图和当前状态，写一条导演旁白和一条短标题。只返回 JSON。",
            state_prompt={
                "trigger": payload.get("trigger", ""),
                "day": payload.get("day", 1),
                "macro": payload.get("macro", {}),
                "current_district": observation.get("current_district", ""),
                "scene_context": observation.get("scene_context", {}),
                "headlines": payload.get("headlines", []),
            },
            screenshot_b64=observation.get("screenshot_b64", ""),
        )

    def generate_npc_spin(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        scene_observation = payload.get("scene_observation", {})
        return self._request_json(
            task_type="npc_spin",
            schema_hint='{"stance":"立场","truthfulness":0.0,"market_tilt":"neutral","lines":["一句说法"]}',
            system_prompt=(
                "你只负责包装一个 NPC 当下会怎么说。"
                "必须只输出简体中文 JSON。"
                "语气冷静、现实、逐利，但要符合该角色的职业、家族、负债和生活处境。"
                "不能篡改规则层事实。"
            ),
            task_prompt="根据角色档案、独立记忆、街区信号和截图，写出这名 NPC 当下会抛出的说法。只返回 JSON。",
            state_prompt={
                "npc": payload.get("npc", {}),
                "agent_profile": payload.get("agent_profile", {}),
                "topic": payload.get("topic", {}),
                "truth_profile": payload.get("truth_profile", {}),
                "district_signals": payload.get("district_signals", {}),
                "relationship_memory": payload.get("relationship_memory", {}),
                "recent_briefs": payload.get("recent_briefs", []),
                "scene_context": scene_observation.get("scene_context", {}),
            },
            screenshot_b64=scene_observation.get("screenshot_b64", ""),
        )

    def generate_family_briefing(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        scene_observation = payload.get("scene_observation", {})
        return self._request_json(
            task_type="family_briefing",
            schema_hint='{"public_line":"公开口风","hidden_line":"暗线口风","focus":"焦点","signal":"steady"}',
            system_prompt=(
                "你负责家族简报。"
                "必须只输出简体中文 JSON。"
                "公开口风和暗线口风都要短、狠、像权力机关，不得虚构价格和账户数字。"
            ),
            task_prompt="根据家族动作、控制公司和街区压力写一段公开口风和暗线口风。只返回 JSON。",
            state_prompt={
                "family": payload.get("family", {}),
                "controlled_companies": payload.get("controlled_companies", []),
                "district_signals": payload.get("district_signals", {}),
                "recent_briefs": payload.get("recent_briefs", []),
                "scene_context": scene_observation.get("scene_context", {}),
            },
            screenshot_b64=scene_observation.get("screenshot_b64", ""),
        )

    def generate_company_briefing(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        scene_observation = payload.get("scene_observation", {})
        return self._request_json(
            task_type="company_briefing",
            schema_hint='{"headline":"公司摘要","worker_note":"工人感受","risk_note":"风险提示","signal":"steady"}',
            system_prompt=(
                "你负责公司层简报。"
                "必须只输出简体中文 JSON。"
                "不得编造经营数字和资产涨跌，只能包装输入里的经营状态和风险。"
            ),
            task_prompt="根据公司经营状态、街区压力和近期简报写出公司摘要。只返回 JSON。",
            state_prompt={
                "company": payload.get("company", {}),
                "district_signals": payload.get("district_signals", {}),
                "recent_briefs": payload.get("recent_briefs", []),
                "scene_context": scene_observation.get("scene_context", {}),
            },
            screenshot_b64=scene_observation.get("screenshot_b64", ""),
        )

    def generate_pulse_brief(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        scene_observation = payload.get("scene_observation", {})
        return self._request_json(
            task_type="pulse_brief",
            schema_hint=(
                '{"pulse_summary":"一句总览","market_note":"一句市场提示","scene_focus":"一句场景焦点",'
                '"npc_updates":[{"id":"npc_id","line":"一句口风","stance":"立场","market_tilt":"neutral"}],'
                '"family_updates":[{"name":"家族名","public_line":"公开动作","hidden_line":"暗线动作","focus":"焦点","signal":"steady"}],'
                '"company_updates":[{"id":"company_id","headline":"一句公司状态","worker_note":"工人感受","risk_note":"风险提示","signal":"steady"}]}'
            ),
            system_prompt=(
                "你是《壳与市场》的五分钟 AI 脉冲导演。"
                "必须只输出简体中文 JSON。"
                "覆盖所有输入里的 NPC、家族和公司，但只能总结已有状态，不得编造价格、余额或胜负结果。"
            ),
            task_prompt="用截图、市场状态、家族、公司和 NPC 摘要生成一次 AI 脉冲简报。只返回 JSON。",
            state_prompt={
                "trigger": payload.get("trigger", ""),
                "day": payload.get("day", 1),
                "macro": payload.get("macro", {}),
                "district_signals": payload.get("district_signals", {}),
                "player": payload.get("player", {}),
                "goods": payload.get("goods", []),
                "stocks": payload.get("stocks", []),
                "families": payload.get("families", []),
                "companies": payload.get("companies", []),
                "npcs": payload.get("npcs", []),
                "scene_context": scene_observation.get("scene_context", {}),
                "current_district": scene_observation.get("current_district", ""),
            },
            screenshot_b64=scene_observation.get("screenshot_b64", ""),
        )

    def generate_conversation(self, payload: dict[str, Any]) -> list[str] | None:
        generated = self.generate_dialogue_turn(payload)
        if not generated:
            return None
        lines = generated.get("lines", [])
        if isinstance(lines, list) and len(lines) >= 2:
            return [str(lines[0]), str(lines[1])]
        return None

    def generate_news(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        return self.generate_news_copy(payload)

    def generate_scene_direction(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        return self.generate_scene_read(payload)

    def probe(self) -> dict[str, Any]:
        if not self.enabled:
            return {
                "ok": False,
                "message": "方舟客户端未启用，当前仍在规则回退模式。",
                "endpoint_id": self.endpoint_id,
                "model_label": self.model_label,
            }
        errors: list[str] = []
        for model_name in self._model_candidates():
            try:
                response = self._client.chat.completions.create(
                    model=model_name,
                    temperature=0.2,
                    extra_body=THINKING_DISABLED_BODY,
                    messages=[
                        {"role": "system", "content": "你是连通性测试助手，只能用简体中文回复。" + REPLY_LIMIT_SUFFIX},
                        {"role": "user", "content": "请只回答：方舟连通。"},
                    ],
                )
                content = response.choices[0].message.content or ""
                return {
                    "ok": True,
                    "message": content.strip(),
                    "endpoint_id": self.endpoint_id,
                    "model_id": model_name,
                    "model_label": model_name,
                }
            except Exception as exc:
                errors.append(f"{model_name}: {exc}")
        return {
            "ok": False,
            "message": " | ".join(errors),
            "endpoint_id": self.endpoint_id,
            "model_id": self.model_id,
            "model_label": self.model_label,
        }

    def _request_json(
        self,
        *,
        task_type: str,
        schema_hint: str,
        system_prompt: str,
        task_prompt: str,
        state_prompt: dict[str, Any],
        screenshot_b64: str = "",
    ) -> dict[str, Any] | None:
        if not self.enabled:
            return None
        prompt = {
            "task_type": task_type,
            "task_prompt": task_prompt + REPLY_LIMIT_SUFFIX + ANTI_PLACEHOLDER_SUFFIX,
            "schema_hint": schema_hint,
            "state": state_prompt,
        }
        system_prompt = system_prompt + REPLY_LIMIT_SUFFIX + ANTI_PLACEHOLDER_SUFFIX
        for model_name in self._model_candidates():
            try:
                response = self._client.chat.completions.create(
                    model=model_name,
                    temperature=0.45,
                    max_tokens=320,
                    extra_body=THINKING_DISABLED_BODY,
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {
                            "role": "user",
                            "content": self._build_multimodal_content(json.dumps(prompt, ensure_ascii=False), screenshot_b64),
                        },
                    ],
                )
                content = response.choices[0].message.content or ""
                parsed = self._extract_json(content)
                if not parsed:
                    continue
                if not self._looks_usable_chinese(parsed):
                    continue
                if isinstance(parsed, dict):
                    parsed["_meta_model"] = model_name
                return parsed
            except Exception:
                continue
        return None

    @staticmethod
    def _extract_json(content: str) -> dict[str, Any]:
        match = re.search(r"\{.*\}", content, re.S)
        if not match:
            return {}
        try:
            return json.loads(match.group(0))
        except json.JSONDecodeError:
            return {}

    def _model_candidates(self) -> list[str]:
        candidates: list[str] = []
        for value in [self.endpoint_id, self.model_id, self.model_label, *DEFAULT_ARK_MODEL_CANDIDATES]:
            cleaned = str(value).strip()
            if cleaned and cleaned not in candidates:
                candidates.append(cleaned)
        return candidates

    @staticmethod
    def _build_multimodal_content(text_prompt: str, screenshot_b64: str) -> Any:
        if not screenshot_b64:
            return text_prompt
        return [
            {"type": "text", "text": text_prompt},
            {
                "type": "image_url",
                "image_url": {"url": f"data:image/png;base64,{screenshot_b64}"},
            },
        ]

    def _looks_usable_chinese(self, payload: Any) -> bool:
        critical = self._collect_leaf_strings(payload)
        if not critical:
            return False
        if self._contains_placeholder_schema_value(critical):
            return False
        chinese_hits = 0
        latin_hits = 0
        for text in critical:
            stripped = text.strip()
            if not stripped:
                continue
            if re.search(r"[\u4e00-\u9fff]", stripped):
                chinese_hits += 1
            if re.search(r"[A-Za-z]{4,}", stripped):
                latin_hits += 1
        return chinese_hits > 0 and latin_hits <= max(2, chinese_hits * 2)

    @staticmethod
    def _contains_placeholder_schema_value(rows: list[str]) -> bool:
        exact_placeholders = {
            "玩家台词",
            "NPC台词",
            "立场",
            "topic_id",
            "信息不足",
            "未知",
        }
        suspicious_phrases = (
            "任务执行中，信息待补充",
            "当前城区信息缺失",
            "待观察商品、股票动态",
            "待补充",
            "口风待补充",
            "立场待补充",
            "无有效信息",
            "无市场动态",
            "无场景焦点",
            "话术补全",
            "字段定义",
            "json 格式",
            "只输出这个对象",
            "只返回 json",
            "schema_hint",
        )
        seen_exact = 0
        for value in rows:
            stripped = value.strip()
            if not stripped:
                continue
            if stripped in exact_placeholders:
                seen_exact += 1
                continue
            if any(phrase in stripped.lower() for phrase in suspicious_phrases):
                return True
        return seen_exact >= 2

    def _collect_leaf_strings(self, payload: Any) -> list[str]:
        rows: list[str] = []
        if isinstance(payload, dict):
            for value in payload.values():
                rows.extend(self._collect_leaf_strings(value))
        elif isinstance(payload, list):
            for value in payload:
                rows.extend(self._collect_leaf_strings(value))
        elif isinstance(payload, str):
            rows.append(payload)
        return rows
