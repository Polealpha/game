from __future__ import annotations

import json
import os
import re
from typing import Any

try:
    from openai import OpenAI
except Exception:  # pragma: no cover
    OpenAI = None


class ArkClient:
    def __init__(self) -> None:
        self.api_key = os.getenv("ARK_API_KEY", "").strip()
        self.endpoint_id = os.getenv("ARK_ENDPOINT_ID", "").strip()
        self.model_id = os.getenv("ARK_MODEL_ID", "doubao-seed-2-0-mini").strip()
        self.model_label = os.getenv("ARK_MODEL_LABEL", "Doubao Seed 2.0 mini").strip()
        self.base_url = os.getenv("ARK_BASE_URL", "https://ark.cn-beijing.volces.com/api/v3")
        self.timeout_seconds = float(os.getenv("ARK_TIMEOUT_SECONDS", "20").strip() or "20")
        self._client = None
        if self.api_key and OpenAI is not None:
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
                "You write dialogue for a medieval pixel-art animal capitalist city simulation. "
                "Output concise Chinese lines in a cold, realistic, profit-driven tone. "
                "Do not invent prices, asset changes, or world events beyond the provided state."
            ),
            task_prompt=(
                "Generate one dialogue turn based on the two characters, the topic, the speaking approach, "
                "and the current scene. If player_input is present, use it as the exact player line and make the NPC answer it directly. Return JSON only."
            ),
            state_prompt={
                "speaker": payload.get("speaker", {}),
                "listener": payload.get("listener", {}),
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
            schema_hint='{"title":"标题","body":"正文","tags":["标签"],"tone":"tone"}',
            system_prompt=(
                "You are an editor in the animal capitalist city. "
                "Package only the provided facts into concise Chinese news copy. "
                "Do not invent market results, balance changes, or event outcomes."
            ),
            task_prompt="Turn the provided event, macro state, and market context into one short news item. Return JSON only.",
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
                "You are the director AI of a social simulation game. "
                "Summarize atmosphere and visible tension in concise Chinese. "
                "Do not invent new system results."
            ),
            task_prompt="Based on the screenshot and current state, write one director note and one short headline. Return JSON only.",
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
                "You only package an NPC's motive and wording. "
                "Output concise Chinese in a cold, realistic tone. "
                "Do not change the underlying facts from the rule system."
            ),
            task_prompt="Generate how this NPC would phrase the situation right now. Return JSON only.",
            state_prompt={
                "npc": payload.get("npc", {}),
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
                "You write a powerful family's public wording and hidden posture. "
                "Output concise Chinese. Do not invent cash, prices, or event truth."
            ),
            task_prompt="Write a short family briefing from the provided movement, pressure, and controlled companies. Return JSON only.",
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
                "You write a company's expression layer. "
                "Output concise Chinese. Do not invent operating numbers or asset changes."
            ),
            task_prompt="Write a short company briefing from the provided operating state and pressure. Return JSON only.",
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
                '{"pulse_summary":"一句总览","market_note":"一句市场注释","scene_focus":"一句场景焦点",'
                '"npc_updates":[{"id":"npc_id","line":"一句口风","stance":"立场","market_tilt":"neutral"}],'
                '"family_updates":[{"name":"家族名","public_line":"公开动作","hidden_line":"暗线动作","focus":"焦点","signal":"steady"}],'
                '"company_updates":[{"id":"company_id","headline":"一句公司状态","worker_note":"工人感受","risk_note":"风险提示","signal":"steady"}]}'
            ),
            system_prompt=(
                "You are the pulse director of a social-capital city simulation. "
                "Summarize and phrase what is already present in the supplied state. "
                "Do not invent prices, balance changes, or event truth. "
                "Cover every NPC id provided in the input if possible."
            ),
            task_prompt=(
                "Use the screenshot, market state, families, companies, and all NPC summaries to produce a five-minute pulse brief. "
                "Return JSON only."
            ),
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
                "message": "ARK_API_KEY 未配置，当前仍处于本地 mock 模式。",
                "endpoint_id": self.endpoint_id,
                "model_label": self.model_label,
            }
        try:
            errors: list[str] = []
            for model_name in self._model_candidates():
                try:
                    response = self._client.chat.completions.create(
                        model=model_name,
                        temperature=0.2,
                        messages=[
                            {"role": "system", "content": "你是连通性测试助手，只回复一句极短中文。"},
                            {"role": "user", "content": "请只回复：方舟连通。"},
                        ],
                    )
                    content = response.choices[0].message.content or ""
                    return {
                        "ok": True,
                        "message": content.strip(),
                        "endpoint_id": self.endpoint_id,
                        "model_id": model_name,
                        "model_label": self.model_label,
                    }
                except Exception as inner_exc:
                    errors.append(f"{model_name}: {inner_exc}")
            return {
                "ok": False,
                "message": " | ".join(errors),
                "endpoint_id": self.endpoint_id,
                "model_id": self.model_id,
                "model_label": self.model_label,
            }
        except Exception as exc:
            return {
                "ok": False,
                "message": str(exc),
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
            "task_prompt": task_prompt,
            "schema_hint": schema_hint,
            "state": state_prompt,
        }
        try:
            for model_name in self._model_candidates():
                response = self._client.chat.completions.create(
                    model=model_name,
                    temperature=0.65,
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
                if parsed:
                    return parsed
        except Exception:
            return None
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
        for value in [
            self.endpoint_id,
            self.model_id,
            self.model_label,
            "doubao-seed-2-0-mini",
            "doubao-seed-2.0-mini",
            "Doubao-Seed-2.0-mini",
        ]:
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
                "image_url": {
                    "url": f"data:image/png;base64,{screenshot_b64}"
                },
            },
        ]
