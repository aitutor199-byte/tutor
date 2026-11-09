# 🛠️ Supabase & Gemini Setup Guide

This guide walks you step-by-step through setting up your backend services using **free-tier accounts**. You do not need to pay for anything in Phase 1.

---

## Part 1: Get Your Free Google Gemini API Key

1. Visit [Google AI Studio](https://aistudio.google.com/).
2. Sign in with your Google account.
3. Click **Get API key** in the top left.
4. Click **Create API key** (you can create it in a new Google Cloud project).
5. Copy your API key (it looks like `AIzaSy...`).
6. Keep this secret. **Never share it or paste it into client code.**

---

## Part 2: Create Your Free Supabase Project

1. Visit [Supabase](https://supabase.com/) and click **Start your project** (free tier).
2. Click **New project**:
   - **Name**: `ai-tutor`
   - **Database Password**: Choose a strong password and save it securely.
   - **Region**: Choose the region closest to your users (e.g., Frankfurt, Singapore, or US East).
3. Wait 1–2 minutes for the database to provision.

---

## Part 3: Apply the Database Schema

1. In your Supabase Dashboard, go to **SQL Editor** (left sidebar icon with `>_`).
2. Click **New query**.
3. Open the file `supabase/migrations/20261109000000_init_schema.sql` from this repository.
4. Copy the entire contents and paste into the SQL Editor.
5. Click **Run** (green button).
6. You should see `Success. No rows returned`.
7. Go to **Table Editor** to confirm you now have `profiles`, `conversations`, and `messages` tables with RLS active.

---

## Part 4: Deploy the Gemini Edge Function

You can deploy the Edge Function using either the **Supabase CLI** or directly through the **Supabase Dashboard**:

### Option A: Using the Supabase CLI (Recommended)

1. Install Supabase CLI (if not installed):
   ```powershell
   npm install -g supabase
   ```
2. Log in to your Supabase account:
   ```powershell
   supabase login
   ```
3. Link your local project (replace `your-project-ref` with your Project Reference ID from Supabase Project Settings):
   ```powershell
   cd d:\Tutor
   supabase link --project-ref your-project-ref
   ```
4. Set your Gemini API key secret in Supabase:
   ```powershell
   supabase secrets set GEMINI_API_KEY="AIzaSyYourGeminiApiKeyHere"
   ```
5. Deploy the Edge Function:
   ```powershell
   supabase functions deploy gemini-chat --no-verify-jwt
   ```

### Option B: Supabase Dashboard
1. Go to **Edge Functions** in your Supabase dashboard.
2. Click **Create function** and name it `gemini-chat`.
3. Paste the contents of `supabase/functions/gemini-chat/index.ts`.
4. Go to **Settings > Secrets** in Supabase and add a secret named `GEMINI_API_KEY` with your Google Gemini key.

---

## Part 5: Connect the App to Your Backend

1. In your Supabase Dashboard, go to **Project Settings > API**.
2. Copy two values:
   - **Project URL** (e.g., `https://xyzabcdefg.supabase.co`)
   - **Project API keys > `anon` `public`** (e.g., `eyJhbGciOi...`)
3. Launch the **AI Tutor** app:
   ```powershell
   cd d:\Tutor
   flutter run -d chrome
   ```
4. Tap the **Settings** tab in the app's bottom navigation.
5. Paste your **Project URL** and **Anon Key**.
6. Tap **Save**.
7. Go to the **Chat** tab and ask a question! Your AI Tutor will now reply with live, tailored explanations from Gemini.

---

## 💰 Cost & Free-Tier Clarification

| Service | Free Tier Allowance | When Paid Tier is Needed |
| :--- | :--- | :--- |
| **Google Gemini 1.5 Flash** | 15 Requests Per Minute (RPM), 1,500 Requests Per Day | Only if exceeding 1,500 daily requests across all users. Paid tier costs ~$0.075 per 1 million input tokens. |
| **Supabase** | 500 MB database, 50,000 monthly active users, 500K Edge Function invocations/month | Only if exceeding 50,000 active students or 500,000 monthly queries. Pro tier is \$25/month. |
| **Flutter / Dart** | 100% Free & Open Source | Never. |
| **Speech recognition / TTS** | Uses device-native engines | Free. Custom cloud voices (e.g. Google Cloud TTS) would require payment later if desired. |
