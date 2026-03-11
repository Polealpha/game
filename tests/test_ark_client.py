from __future__ import annotations

import unittest

from services.ark_client import ArkClient


class ArkClientDialogueNormalizationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.client = ArkClient()

    def test_thinking_is_disabled_by_default(self) -> None:
        self.assertEqual(self.client.thinking_disabled_body(), {"thinking": {"type": "disabled"}})

    def test_normalize_dialogue_turn_extracts_line_from_raw_json_blob(self) -> None:
        parsed = {
            "lines": [
                "玩家原话",
                '{"lines":["玩家原话","我跟你说，码头那边有人在抛货。"],"stance":"谨慎","truthfulness":0.58}',
            ],
            "stance": "谨慎",
            "truthfulness": 0.58,
        }
        normalized = self.client._normalize_dialogue_turn(parsed, {"player_input": "玩家原话"})
        self.assertEqual(normalized["lines"][1], "我跟你说，码头那边有人在抛货。")

    def test_normalize_dialogue_turn_rejects_schema_echo_and_uses_reply_field(self) -> None:
        parsed = {
            "lines": ["玩家原话", '{"schema":"lines, stance, truthfulness"}'],
            "reply": "别把名字喊出来，消息是真的。",
            "stance": "敷衍",
            "truthfulness": 0.44,
        }
        normalized = self.client._normalize_dialogue_turn(parsed, {"player_input": "玩家原话"})
        self.assertEqual(normalized["lines"][1], "别把名字喊出来，消息是真的。")


if __name__ == "__main__":
    unittest.main()
