# game

A simple number-guessing game written in Python.

## How to play

Run the game from the command line:

```bash
python game.py
```

The program will pick a secret number between 1 and 100. You have 10 attempts to guess it. After each guess you will be told whether your guess was too low or too high.

## Running tests

```bash
python -m pytest test_game.py -v
```
