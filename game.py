import random


def generate_secret_number(low=1, high=100):
    """Generate a random secret number between low and high (inclusive)."""
    return random.randint(low, high)


def check_guess(guess, secret):
    """
    Compare the guess to the secret number.
    Returns 'low', 'high', or 'correct'.
    """
    if guess < secret:
        return "low"
    elif guess > secret:
        return "high"
    else:
        return "correct"


def play(low=1, high=100, max_attempts=10, input_fn=input, print_fn=print):
    """
    Run one round of the number guessing game.

    Returns the number of attempts taken, or None if the player gave up.
    """
    secret = generate_secret_number(low, high)
    print_fn(f"I'm thinking of a number between {low} and {high}.")
    print_fn(f"You have {max_attempts} attempts. Good luck!")

    for attempt in range(1, max_attempts + 1):
        raw = input_fn(f"Attempt {attempt}/{max_attempts} - Your guess: ")
        try:
            guess = int(raw)
        except ValueError:
            print_fn("Please enter a valid integer.")
            continue

        result = check_guess(guess, secret)
        if result == "correct":
            print_fn(f"Correct! You guessed the number in {attempt} attempt(s)!")
            return attempt
        elif result == "low":
            print_fn("Too low! Try higher.")
        else:
            print_fn("Too high! Try lower.")

    print_fn(f"Game over! The secret number was {secret}.")
    return None


if __name__ == "__main__":
    play()
