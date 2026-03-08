import pytest
from game import check_guess, generate_secret_number, play


def test_check_guess_low():
    assert check_guess(5, 10) == "low"


def test_check_guess_high():
    assert check_guess(15, 10) == "high"


def test_check_guess_correct():
    assert check_guess(10, 10) == "correct"


def test_generate_secret_number_in_range():
    for _ in range(100):
        n = generate_secret_number(1, 10)
        assert 1 <= n <= 10


def test_generate_secret_number_custom_range():
    n = generate_secret_number(50, 50)
    assert n == 50


def test_play_correct_on_first_guess():
    """Player guesses correctly on the first attempt."""
    import random
    original_randint = random.randint
    random.randint = lambda a, b: 42

    try:
        inputs = iter(["42"])
        messages = []
        attempts = play(
            low=1,
            high=100,
            max_attempts=5,
            input_fn=lambda _: next(inputs),
            print_fn=lambda msg: messages.append(msg),
        )
    finally:
        random.randint = original_randint

    assert attempts == 1
    assert any("Correct" in m for m in messages)


def test_play_runs_out_of_attempts():
    """Player never guesses correctly and exhausts all attempts."""
    # Force secret to 50; feed guesses that are always wrong
    import game as game_module
    original_randint = __import__("random").randint

    import random
    random.randint = lambda a, b: 50  # fix secret to 50

    try:
        inputs = iter(["1", "2", "3"])  # all too low
        messages = []
        result = play(
            low=1,
            high=100,
            max_attempts=3,
            input_fn=lambda _: next(inputs),
            print_fn=lambda msg: messages.append(msg),
        )
    finally:
        random.randint = original_randint

    assert result is None
    assert any("Game over" in m for m in messages)


def test_play_invalid_then_correct():
    """Invalid input is handled gracefully; player eventually wins."""
    import random
    original_randint = random.randint
    random.randint = lambda a, b: 7

    try:
        inputs = iter(["abc", "7"])
        messages = []
        attempts = play(
            low=1,
            high=100,
            max_attempts=5,
            input_fn=lambda _: next(inputs),
            print_fn=lambda msg: messages.append(msg),
        )
    finally:
        random.randint = original_randint

    assert attempts == 2
    assert any("valid integer" in m for m in messages)
