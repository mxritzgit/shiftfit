# Privacy Policy — FitPilot

_Last updated: 2026-06-02_

FitPilot ("the app") is a fitness, recovery, and nutrition tracker. This policy
explains what data the app processes, why, and the rights you have over it. It is
written to satisfy GDPR (Art. 13/15–20) and the Apple App Store / Google Play
health-data requirements.

**Controller:** Moritz Gietl · moritz.gietl@gmail.com

## What data we process

You enter and the app stores the following, tied to your account:

- **Profile / body metrics:** name, email, weight, height, age, biological sex,
  activity level, goal weight, and your daily targets (calories, macros, steps,
  water, sleep).
- **Nutrition log:** meals you log (name, calories, macros, portion, barcode/brand
  where applicable), favorites, and your own recipes.
- **Health & wellness log:** weight history, sleep entries, caffeine intake, mood,
  habits, water and step counts, and your completed workout days / streak.
- **Coach chat:** the messages you send to the in-app AI coach and its replies.
- **Apple Health (optional):** if you grant permission, the app reads your step
  count for the day. It does not read other health categories and does not write
  back to Apple Health.

We do **not** collect advertising identifiers, location, or contacts, and the app
contains no third-party analytics or ad SDKs.

## Where it is stored and who processes it

- **Supabase** (Postgres + Auth, EU region) hosts your account and all the data
  above. Every row is protected by row-level security so it is only accessible to
  your authenticated account.
- **OpenAI / OpenRouter** processes your coach-chat messages and the photo you
  submit for AI meal analysis, solely to generate the response. These requests run
  through our server (Supabase Edge Functions); your API traffic is not used to
  train models under the configured API terms.
- **OpenFoodFacts** (and our self-hosted search mirror) is queried for public
  product/nutrition data when you search or scan a barcode. Your identity is not
  sent with these queries.

API keys for these services live only on our server, never in the app.

## Why (legal basis)

We process this data to provide the tracking features you ask for — i.e. to perform
the service you signed up for (GDPR Art. 6(1)(b)), and, for the optional Apple Health
read and AI features, on the basis of the explicit permission you grant in-app
(Art. 6(1)(a), Art. 9 for health data).

## Your rights

You can, at any time:

- **Access / export** your data (see in-app export, and you may request a full copy
  by email).
- **Correct** any value directly in the app.
- **Delete** your account and all associated data — in-app via Profile → Account
  löschen, which removes your auth record and cascades to every table.
- **Withdraw consent** for Apple Health (in iOS Settings) or AI features (by not
  using them).

To exercise a right or ask a question, contact **moritz.gietl@gmail.com**. You also
have the right to lodge a complaint with your data-protection authority.

## Retention

Data is kept until you delete it or delete your account. Coach-chat history is kept
so you can revisit conversations; you can delete individual chat sessions in-app.

## Children

FitPilot is not directed at children under 16 and should not be used by them.

## Changes

We will update the "Last updated" date above when this policy changes. Material
changes will be surfaced in-app.
