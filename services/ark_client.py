from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeoutError
import json
import os
import re
import sys
from typing import Any, Callable

try:
    from openai import OpenAI
except Exception:  # pragma: no cover
    OpenAI = None


HARDCODED_ARK_API_KEY = "521e4c18-b3f9-4b54-af94-1f404328f300"
FORCED_ARK_MODEL = "doubao-seed-2-0-mini-260215"
REPLY_LIMIT_SUFFIX = "每次回复都要简短、具体、只说眼下这轮需要的话。"
ANTI_PLACEHOLDER_SUFFIX = "不要重复字段名、示例值、schema_hint 或提示词原文。不要输出英文说明。"
THINKING_DISABLED_BODY = {
    "thinking": {"type": "disabled"},
    "reasoning_effort": "minimal",
}
DEFAULT_ARK_MODEL_CANDIDATES = [FORCED_ARK_MODEL]

# Override earlier mojibake literals with the intended low-latency Chinese prompts.
REPLY_LIMIT_SUFFIX = "每次回复都要简短、具体、只说眼下这轮需要的话。"
ANTI_PLACEHOLDER_SUFFIX = "不要重复字段名、示例值、schema_hint 或提示词原文。不要输出英文说明。"


class ArkClient:
    def __init__(self) -> None:
        self.api_key = HARDCODED_ARK_API_KEY
        raw_endpoint_id = os.getenv("ARK_ENDPOINT_ID", "").strip()
        self.endpoint_id = "" if raw_endpoint_id == self.api_key else raw_endpoint_id
        # Lock the runtime model to the low-latency 2.0 mini variant so .env cannot silently override it.
        self.model_id = FORCED_ARK_MODEL
        self.model_label = FORCED_ARK_MODEL
        self.base_url = os.getenv("ARK_BASE_URL", "https://ark.cn-beijing.volces.com/api/v3")
        # Keep dialogue latency low and let the frontend retry once if a round stalls.
        self.timeout_seconds = float(os.getenv("ARK_TIMEOUT_SECONDS", "6.5").strip() or "6.5")
        self.hard_timeout_seconds = float(os.getenv("ARK_HARD_TIMEOUT_SECONDS", "8.0").strip() or "8.0")
        self._request_executor = ThreadPoolExecutor(max_workers=4, thread_name_prefix="ark-client")
        self._client = None
        disable_for_unittest = "unittest" in sys.modules and os.getenv("ARK_ENABLE_IN_TESTS", "0") != "1"
        if self.api_key and OpenAI is not None and not disable_for_unittest:
            self._client = OpenAI(api_key=self.api_key, base_url=self.base_url, timeout=self.timeout_seconds)

    @property
    def enabled(self) -> bool:
        return self._client is not None

    def _create_completion(self, **kwargs: Any) -> Any:
        if self._client is None:
            raise RuntimeError("ark client disabled")
        future = self._request_executor.submit(self._client.chat.completions.create, **kwargs)
        try:
            return future.result(timeout=self.hard_timeout_seconds)
        except FuturesTimeoutError as exc:
            future.cancel()
            raise TimeoutError(f"ark hard timeout after {self.hard_timeout_seconds:.1f}s") from exc

    def generate_dialogue_turn(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        scene_observation = payload.get("scene_observation", {})
        return self._request_json(
            task_type="dialogue_turn",
            schema_hint='{"lines":["玩家原话","NPC回话"],"stance":"谨慎/强硬/敷衍/热心","truthfulness":0.58,"revealed_topic_ids":["market_whisper"]}',
            system_prompt=(
                "你是《壳与市场》的 NPC 对话引擎。"
                "你只负责生成一轮贴近身份的中文对话。"
                "玩家台词必须原样复述到 lines[0]。"
                "NPC 台词放到 lines[1]，必须结合职业、家族、债务、饥饿、立场和最近记忆来回答。"
                "不能讲英文，不能解释规则，不能自称模型。"
            ),
            task_prompt=(
                "请按给定字段直接返回一个 JSON 对象。"
                "如果信息不足，也要以角色口吻谨慎回答，不能空白。"
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
            normalizer=lambda parsed: self._normalize_dialogue_turn(parsed, payload),
        )

    def generate_news_copy(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        scene_observation = payload.get("scene_observation", {})
        return self._request_json(
            task_type="news_copy",
            schema_hint='{"title":"标题","body":"正文","tags":["街区","市场"],"tone":"冷静/煽动/审慎"}',
            system_prompt=(
                "你是《壳与市场》的城内新闻编辑。"
                "只把输入里已经存在的市场变化、街区情绪和事件包装成一条短新闻。"
                "不要编造额外价格、余额或世界结果。"
            ),
            task_prompt="输出一条适合 HUD 和新闻栏展示的中文短新闻，只返回一个 JSON 对象。",
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
            normalizer=self._normalize_news_copy,
        )

    def generate_scene_read(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        observation = payload.get("scene_observation", {})
        return self._request_json(
            task_type="scene_read",
            schema_hint='{"director_note":"导演旁白","headline_title":"标题","headline_body":"一句摘要"}',
            system_prompt=(
                "你是《壳与市场》的场景导演。"
                "只总结画面氛围、街头紧张感、交易热度和舆论温度。"
                "不要编造成败结果。"
            ),
            task_prompt="根据画面和状态写一句导演旁白与一句标题摘要，只返回一个 JSON 对象。",
            state_prompt={
                "trigger": payload.get("trigger", ""),
                "day": payload.get("day", 1),
                "macro": payload.get("macro", {}),
                "current_district": observation.get("current_district", ""),
                "scene_context": observation.get("scene_context", {}),
                "headlines": payload.get("headlines", []),
            },
            screenshot_b64=observation.get("screenshot_b64", ""),
            normalizer=self._normalize_scene_read,
        )

    def generate_npc_spin(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        scene_observation = payload.get("scene_observation", {})
        return self._request_json(
            task_type="npc_spin",
            schema_hint='{"stance":"谨慎/乐观/恐慌/挑衅","truthfulness":0.56,"market_tilt":"bullish/bearish/neutral","lines":["一句角色说法"]}',
            system_prompt=(
                "你只负责写一名 NPC 此刻会丢出的说法。"
                "语气必须符合该角色的职业、家族、债务、饥饿和街区位置。"
                "只返回一个 JSON 对象。"
            ),
            task_prompt="给出一条适合街头耳语或人物短句展示的中文说法。",
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
            normalizer=self._normalize_npc_spin,
        )

    def generate_family_briefing(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        scene_observation = payload.get("scene_observation", {})
        return self._request_json(
            task_type="family_briefing",
            schema_hint='{"public_line":"公开动作","hidden_line":"暗线动作","focus":"焦点","signal":"steady/rising/falling"}',
            system_prompt=(
                "你负责写家族简报。"
                "公开口风要像外放消息，暗线口风要像内部意图。"
                "不能编造资产数字。"
            ),
            task_prompt="根据家族控制力和街区压力写公开口风与暗线口风，只返回一个 JSON 对象。",
            state_prompt={
                "family": payload.get("family", {}),
                "controlled_companies": payload.get("controlled_companies", []),
                "district_signals": payload.get("district_signals", {}),
                "recent_briefs": payload.get("recent_briefs", []),
                "scene_context": scene_observation.get("scene_context", {}),
            },
            screenshot_b64=scene_observation.get("screenshot_b64", ""),
            normalizer=self._normalize_family_briefing,
        )

    def generate_company_briefing(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        scene_observation = payload.get("scene_observation", {})
        return self._request_json(
            task_type="company_briefing",
            schema_hint='{"headline":"公司摘要","worker_note":"工人感受","risk_note":"风险提示","signal":"steady/rising/falling"}',
            system_prompt=(
                "你负责写公司层简报。"
                "只总结经营状态、劳工情绪和风险，不要编造不存在的财务数字。"
            ),
            task_prompt="根据公司状态写一条公司摘要、一条工人感受和一条风险提示，只返回一个 JSON 对象。",
            state_prompt={
                "company": payload.get("company", {}),
                "district_signals": payload.get("district_signals", {}),
                "recent_briefs": payload.get("recent_briefs", []),
                "scene_context": scene_observation.get("scene_context", {}),
            },
            screenshot_b64=scene_observation.get("screenshot_b64", ""),
            normalizer=self._normalize_company_briefing,
        )

    def generate_pulse_brief(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        scene_observation = payload.get("scene_observation", {})
        return self._request_json(
            task_type="pulse_brief",
            schema_hint=(
                '{"pulse_summary":"一句总览","market_note":"一句市场提示","scene_focus":"一句场景焦点",'
                '"npc_updates":[{"id":"npc_id","line":"一句口风","stance":"谨慎","market_tilt":"neutral"}],'
                '"family_updates":[{"name":"家族名","public_line":"公开动作","hidden_line":"暗线动作","focus":"焦点","signal":"steady"}],'
                '"company_updates":[{"id":"company_id","headline":"一句状态","worker_note":"工人感受","risk_note":"风险提示","signal":"steady"}]}'
            ),
            system_prompt=(
                "你是《壳与市场》的分钟级 AI 脉冲编辑。"
                "只总结当前已知状态，覆盖输入里的 NPC、家族和公司。"
                "不要额外编造价格、余额或结局。"
            ),
            task_prompt="请生成一次适合驱动 HUD 和街头耳语更新的中文脉冲摘要，只返回一个 JSON 对象。",
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
            normalizer=self._normalize_pulse_brief,
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
                response = self._create_completion(
                    model=model_name,
                    temperature=0.1,
                    max_tokens=24,
                    extra_body=THINKING_DISABLED_BODY,
                    messages=[
                        {
                            "role": "system",
                            "content": "你是连通性测试助手。必须只返回一个 JSON 对象：{\"message\":\"方舟连通\"}。",
                        },
                        {"role": "user", "content": "请按要求返回。"},
                    ],
                )
                content = self._message_to_text(response.choices[0].message.content)
                parsed = self._extract_json(content)
                message = self._sanitize_text(str(parsed.get("message", "")))
                if not message and "方舟连通" in content:
                    message = "方舟连通"
                if not message:
                    continue
                return {
                    "ok": True,
                    "message": message,
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
        normalizer: Callable[[dict[str, Any]], dict[str, Any]] | None = None,
    ) -> dict[str, Any] | None:
        if not self.enabled:
            return None
        prompt = {
            "task_type": task_type,
            "task_prompt": task_prompt + REPLY_LIMIT_SUFFIX + ANTI_PLACEHOLDER_SUFFIX,
            "schema_hint": schema_hint,
            "state": state_prompt,
        }
        final_system = system_prompt + REPLY_LIMIT_SUFFIX + ANTI_PLACEHOLDER_SUFFIX
        for model_name in self._model_candidates():
            try:
                response = self._create_completion(
                    model=model_name,
                    temperature=0.01,
                    max_tokens=self._task_max_tokens(task_type),
                    extra_body=THINKING_DISABLED_BODY,
                    messages=[
                        {"role": "system", "content": final_system},
                        {
                            "role": "user",
                            "content": self._build_multimodal_content(json.dumps(prompt, ensure_ascii=False), screenshot_b64),
                        },
                    ],
                )
                content = self._message_to_text(response.choices[0].message.content)
                parsed = self._extract_json(content)
                if not parsed and task_type == "dialogue_turn":
                    parsed = self._dialogue_fallback_from_text(content)
                if not parsed:
                    continue
                normalized = normalizer(parsed) if normalizer is not None else parsed
                if not normalized:
                    continue
                if not self._looks_usable_chinese(normalized):
                    continue
                normalized["_meta_model"] = model_name
                return normalized
            except Exception:
                continue
        return None

    @staticmethod
    def _task_max_tokens(task_type: str) -> int:
        if task_type == "dialogue_turn":
            return 96
        if task_type == "npc_spin":
            return 80
        if task_type in {"news_copy", "scene_read"}:
            return 112
        return 192

    @staticmethod
    def _message_to_text(content: Any) -> str:
        if isinstance(content, str):
            return content
        if isinstance(content, list):
            parts: list[str] = []
            for item in content:
                if isinstance(item, dict):
                    text = item.get("text")
                    if isinstance(text, str):
                        parts.append(text)
            return "\n".join(parts)
        return str(content or "")

    @staticmethod
    def _extract_json(content: str) -> dict[str, Any]:
        stripped = content.strip()
        if not stripped:
            return {}
        fenced = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", stripped, re.S)
        if fenced:
            stripped = fenced.group(1)
        try:
            parsed = json.loads(stripped)
            if isinstance(parsed, dict):
                return parsed
            if isinstance(parsed, list) and parsed and isinstance(parsed[0], dict):
                return parsed[0]
        except json.JSONDecodeError:
            pass
        match = re.search(r"\{.*\}", stripped, re.S)
        if not match:
            return {}
        try:
            parsed = json.loads(match.group(0))
            if isinstance(parsed, dict):
                return parsed
        except json.JSONDecodeError:
            return {}
        return {}

    @classmethod
    def _dialogue_fallback_from_text(cls, content: str) -> dict[str, Any]:
        cleaned = cls._sanitize_text(str(content))
        if not cleaned:
            return {}
        lines = [line.strip("：: -") for line in cleaned.splitlines() if line.strip()]
        npc_line = ""
        for line in lines:
            if len(line) >= 6:
                npc_line = line
                break
        if not npc_line:
            npc_line = cleaned[:120]
        return {"lines": ["……", npc_line], "stance": "谨慎", "truthfulness": 0.52}

    def _model_candidates(self) -> list[str]:
        forced_model = str(self.model_id).strip() or FORCED_ARK_MODEL
        return [forced_model]

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

    def _normalize_dialogue_turn(self, parsed: dict[str, Any], payload: dict[str, Any]) -> dict[str, Any]:
        lines = parsed.get("lines", [])
        if not isinstance(lines, list):
            lines = []
        player_input = self._sanitize_text(str(payload.get("player_input", "")).strip())
        player_line = player_input or (self._sanitize_text(str(lines[0])) if len(lines) > 0 else "")
        if not player_line:
            player_line = "……"
        npc_line = self._sanitize_text(str(lines[1])) if len(lines) > 1 else ""
        if not npc_line:
            npc_line = self._sanitize_text(str(parsed.get("reply", "") or parsed.get("npc_reply", "") or parsed.get("line", "")))
        if not npc_line:
            return {}
        stance = self._sanitize_text(str(parsed.get("stance", "谨慎")))
        if not stance:
            stance = "谨慎"
        revealed = parsed.get("revealed_topic_ids", [])
        if not isinstance(revealed, list):
            revealed = [revealed]
        return {
            "lines": [player_line, npc_line],
            "stance": stance,
            "truthfulness": self._clamp_float(parsed.get("truthfulness", 0.55), 0.0, 1.0),
            "revealed_topic_ids": [str(item).strip() for item in revealed if str(item).strip()],
        }

    def _normalize_news_copy(self, parsed: dict[str, Any]) -> dict[str, Any]:
        tags = parsed.get("tags", [])
        if not isinstance(tags, list):
            tags = [tags]
        body = self._sanitize_text(str(parsed.get("body", "")))
        title = self._sanitize_text(str(parsed.get("title", "")))
        if not title or not body:
            return {}
        return {
            "title": title,
            "body": body,
            "tags": [self._sanitize_text(str(tag)) for tag in tags if self._sanitize_text(str(tag))],
            "tone": self._sanitize_text(str(parsed.get("tone", "冷静"))) or "冷静",
        }

    def _normalize_scene_read(self, parsed: dict[str, Any]) -> dict[str, Any]:
        note = self._sanitize_text(str(parsed.get("director_note", "")))
        headline_title = self._sanitize_text(str(parsed.get("headline_title", "")))
        headline_body = self._sanitize_text(str(parsed.get("headline_body", "")))
        if not note:
            return {}
        return {
            "director_note": note,
            "headline_title": headline_title or "街头风向",
            "headline_body": headline_body or note,
        }

    def _normalize_npc_spin(self, parsed: dict[str, Any]) -> dict[str, Any]:
        lines = parsed.get("lines", [])
        if not isinstance(lines, list):
            lines = []
        primary = self._sanitize_text(str(lines[0])) if lines else self._sanitize_text(str(parsed.get("line", "")))
        if not primary:
            return {}
        return {
            "stance": self._sanitize_text(str(parsed.get("stance", "谨慎"))) or "谨慎",
            "truthfulness": self._clamp_float(parsed.get("truthfulness", 0.52), 0.0, 1.0),
            "market_tilt": self._sanitize_market_tilt(str(parsed.get("market_tilt", "neutral"))),
            "lines": [primary],
        }

    def _normalize_family_briefing(self, parsed: dict[str, Any]) -> dict[str, Any]:
        public_line = self._sanitize_text(str(parsed.get("public_line", "")))
        hidden_line = self._sanitize_text(str(parsed.get("hidden_line", "")))
        focus = self._sanitize_text(str(parsed.get("focus", "")))
        if not public_line and not hidden_line:
            return {}
        return {
            "public_line": public_line or "先稳住口风。",
            "hidden_line": hidden_line or "暗线暂不外露。",
            "focus": focus or "保住街区影响力",
            "signal": self._sanitize_signal(str(parsed.get("signal", "steady"))),
        }

    def _normalize_company_briefing(self, parsed: dict[str, Any]) -> dict[str, Any]:
        headline = self._sanitize_text(str(parsed.get("headline", "")))
        worker_note = self._sanitize_text(str(parsed.get("worker_note", "")))
        risk_note = self._sanitize_text(str(parsed.get("risk_note", "")))
        if not headline and not worker_note and not risk_note:
            return {}
        return {
            "headline": headline or "公司口风偏紧。",
            "worker_note": worker_note or "工人还在观望。",
            "risk_note": risk_note or "风险暂时可控。",
            "signal": self._sanitize_signal(str(parsed.get("signal", "steady"))),
        }

    def _normalize_pulse_brief(self, parsed: dict[str, Any]) -> dict[str, Any]:
        summary = self._sanitize_text(str(parsed.get("pulse_summary", "")))
        market_note = self._sanitize_text(str(parsed.get("market_note", "")))
        scene_focus = self._sanitize_text(str(parsed.get("scene_focus", "")))
        if not summary:
            return {}
        return {
            "pulse_summary": summary,
            "market_note": market_note or summary,
            "scene_focus": scene_focus or summary,
            "npc_updates": self._normalize_npc_updates(parsed.get("npc_updates", [])),
            "family_updates": self._normalize_family_updates(parsed.get("family_updates", [])),
            "company_updates": self._normalize_company_updates(parsed.get("company_updates", [])),
        }

    def _normalize_npc_updates(self, rows: Any) -> list[dict[str, Any]]:
        if not isinstance(rows, list):
            return []
        normalized: list[dict[str, Any]] = []
        for row in rows[:20]:
            if not isinstance(row, dict):
                continue
            npc_id = str(row.get("id", "")).strip()
            line = self._sanitize_text(str(row.get("line", "")))
            if not npc_id or not line:
                continue
            normalized.append(
                {
                    "id": npc_id,
                    "line": line,
                    "stance": self._sanitize_text(str(row.get("stance", "谨慎"))) or "谨慎",
                    "market_tilt": self._sanitize_market_tilt(str(row.get("market_tilt", "neutral"))),
                }
            )
        return normalized

    def _normalize_family_updates(self, rows: Any) -> list[dict[str, Any]]:
        if not isinstance(rows, list):
            return []
        normalized: list[dict[str, Any]] = []
        for row in rows[:12]:
            if not isinstance(row, dict):
                continue
            name = self._sanitize_text(str(row.get("name", "")))
            public_line = self._sanitize_text(str(row.get("public_line", "")))
            hidden_line = self._sanitize_text(str(row.get("hidden_line", "")))
            if not name:
                continue
            normalized.append(
                {
                    "name": name,
                    "public_line": public_line or "先稳住门面。",
                    "hidden_line": hidden_line or "暗线继续压着。",
                    "focus": self._sanitize_text(str(row.get("focus", ""))) or "街区影响力",
                    "signal": self._sanitize_signal(str(row.get("signal", "steady"))),
                }
            )
        return normalized

    def _normalize_company_updates(self, rows: Any) -> list[dict[str, Any]]:
        if not isinstance(rows, list):
            return []
        normalized: list[dict[str, Any]] = []
        for row in rows[:12]:
            if not isinstance(row, dict):
                continue
            company_id = str(row.get("id", "")).strip()
            headline = self._sanitize_text(str(row.get("headline", "")))
            if not company_id:
                continue
            normalized.append(
                {
                    "id": company_id,
                    "headline": headline or "公司口风偏紧。",
                    "worker_note": self._sanitize_text(str(row.get("worker_note", ""))) or "工人还在观望。",
                    "risk_note": self._sanitize_text(str(row.get("risk_note", ""))) or "风险仍在累积。",
                    "signal": self._sanitize_signal(str(row.get("signal", "steady"))),
                }
            )
        return normalized

    def _looks_usable_chinese(self, payload: Any) -> bool:
        critical = self._collect_leaf_strings(payload)
        if not critical:
            return False
        if self._contains_placeholder_schema_value(critical):
            return False
        chinese_hits = 0
        text_hits = 0
        for text in critical:
            stripped = text.strip()
            if not stripped:
                continue
            text_hits += 1
            if re.search(r"[\u4e00-\u9fff]", stripped):
                chinese_hits += 1
        return chinese_hits > 0 and chinese_hits >= max(1, text_hits // 3)

    @staticmethod
    def _contains_placeholder_schema_value(rows: list[str]) -> bool:
        exact_placeholders = {
            "玩家原话",
            "NPC回话",
            "立场",
            "topic_id",
            "信息不足",
            "未知",
        }
        suspicious_phrases = (
            "schema_hint",
            "只返回json",
            "只输出json",
            "字段说明",
            "json对象",
            "markdown",
            "example",
            "format",
            "玩家台词",
            "NPC台词",
        )
        seen_exact = 0
        for value in rows:
            stripped = value.strip()
            if not stripped:
                continue
            if stripped in exact_placeholders:
                seen_exact += 1
                continue
            lowered = stripped.lower()
            if any(phrase in lowered for phrase in suspicious_phrases):
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

    @staticmethod
    def _sanitize_text(text: str) -> str:
        cleaned = text.replace("\r", " ").replace("\n", " ").strip()
        cleaned = re.sub(r"^```(?:json)?|```$", "", cleaned).strip()
        cleaned = re.sub(r"\s+", " ", cleaned)
        cleaned = cleaned.replace("：：", "：")
        cleaned = re.sub(r"^(玩家原话|NPC回话|玩家台词|NPC台词|白页|壳仔)\s*[:：]\s*", "", cleaned)
        cleaned = re.sub(r"^(JSON|json)\s*[:：]\s*", "", cleaned)
        return cleaned[:220].strip()

    @staticmethod
    def _sanitize_market_tilt(value: str) -> str:
        lowered = value.strip().lower()
        if lowered in {"bullish", "bearish", "neutral"}:
            return lowered
        return "neutral"

    @staticmethod
    def _sanitize_signal(value: str) -> str:
        lowered = value.strip().lower()
        if lowered in {"steady", "rising", "falling"}:
            return lowered
        return "steady"

    @staticmethod
    def _clamp_float(value: Any, minimum: float, maximum: float) -> float:
        try:
            number = float(value)
        except (TypeError, ValueError):
            return minimum
        return max(minimum, min(maximum, number))
