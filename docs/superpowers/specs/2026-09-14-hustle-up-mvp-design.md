# HUSTLE UP MVP Design

Date: 2026-09-14

## Problem

People freeze in high-stakes moments (offers, arguments, replies, asks). Generic chatbots dump advice. HUSTLE UP answers one question: **WHAT'S THE MOVE?**

## User

Someone who needs a next action in under a minute. Not a journaling audience. Not daters-as-a-category (though a messy text can still be a “reply” situation).

## Core loop

SITUATION → EDGE → RISK → MOVE → EXECUTE (fumble check or practice).

## UX

Dark, typographic, few controls. The analysis screen leads with the move verb, then the reason, then edges and risk. Every screen has a next step.

## Architecture

Protocol-based services, structured Codable models, Vision OCR, mock AI by default. See `docs/PROJECT_MAP.md`.

## Non-goals

Dating product, generic chatbot, voice, real billing, cloud accounts, market-data APIs.

## Success

A user can open the app, drop a situation, see a named move, and know what to do next. Fumble Check and Practice work for Pro. Failures recover. Tests pass. No secrets in the repo.
