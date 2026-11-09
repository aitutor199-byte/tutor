// Supabase Edge Function: gemini-chat
// Secure proxy for Google Gemini API requests
// Deno TypeScript runtime

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-1.5-flash"; // Fast, accurate, cost-effective for education

// Education level system prompts
const EDUCATION_LEVEL_PROMPTS: Record<string, string> = {
  primary: `The student is in primary school (Class 1-5, ages 5-10).
- Use very simple, friendly language and short sentences.
- Use relatable, everyday examples (fruits, toys, animals).
- Avoid complex formulas and jargon.
- Break down explanations into tiny, easy steps.
- Encourage them with enthusiasm and warmth!
- Ask a simple question at the end to check if they understood.`,

  middle: `The student is in middle school (Class 6-8, ages 11-13).
- Use clear, straightforward language.
- Introduce basic technical terms with easy-to-understand definitions.
- Provide step-by-step problem solving with reasoning for each step.
- Use practical examples from daily life and nature.
- Encourage curiosity and critical thinking.
- Check their understanding with a gentle follow-up question.`,

  high: `The student is in high school (Class 9-12, ages 14-18).
- Use proper academic terminology and formal concepts.
- Show complete mathematical derivations, chemical equations, or code syntax.
- Explain "why" things work, not just "how".
- Include real-world applications and exam-relevant insights.
- Encourage analytical problem solving.`,

  college: `The student is in college / intermediate level.
- Use advanced academic language and rigorous explanations.
- Cover theoretical foundations and empirical applications.
- Provide detailed proofs, structured code, or comprehensive literary analysis.
- Connect concepts across disciplines.`,

  university: `The student is at university level (undergraduate / postgraduate).
- Provide rigorous, research-level explanations.
- Cite recognized theories, paradigms, algorithms, and methodologies.
- Analyze edge cases, trade-offs, and critical perspectives.
- Treat the student as an emerging scholar or professional.`,
};

// Language instruction prompts
const LANGUAGE_PROMPTS: Record<string, string> = {
  en: "Respond entirely in English. Use clear, educational English suitable for the student's level.",
  ur: "Respond entirely in Urdu (اردو). Use proper, natural Urdu educational vocabulary. If technical terms are commonly known in English, you may mention them in parentheses, but the main explanation must be in Urdu script.",
  ps: "Respond entirely in Pashto (پښتو). Use authentic, natural Pashto vocabulary. If modern technical terms lack a common Pashto equivalent, you may include the English term in parentheses, but the explanation must be in Pashto script.",
};

// Core tutor persona prompt
function buildSystemPrompt(language: string, educationLevel: string, subject: string): string {
  const levelPrompt = EDUCATION_LEVEL_PROMPTS[educationLevel] || EDUCATION_LEVEL_PROMPTS.high;
  const langPrompt = LANGUAGE_PROMPTS[language] || LANGUAGE_PROMPTS.en;

  return `You are "AI Tutor", a patient, highly knowledgeable, and encouraging personal educator.
Your mission is to help students learn deeply, understand core concepts, and build problem-solving confidence.

### Core Teaching Rules:
1. TEACH, DO NOT JUST GIVE ANSWERS:
   - For math and science, show step-by-step solutions with an explanation of each step.
   - For conceptual questions, give clear explanations and at least one illustrative example.
   - For writing or coding, explain best practices, structure, and underlying logic.
2. ADAPT TO STUDENT LEVEL:
   ${levelPrompt}
3. LANGUAGE REQUIREMENT:
   ${langPrompt}
4. CHILD SAFETY & ETHICS:
   - Always maintain a safe, respectful, educational environment.
   - Never generate hate speech, violence, sexually explicit content, self-harm advice, or illegal activity.
   - If asked non-educational or harmful questions, politely decline and steer back to learning.
   - Do not ask for or store personal identifiable information (full names, home addresses, phone numbers).
5. HONESTY & ACCURACY:
   - Never guess or present uncertainty as fact.
   - If a problem is ambiguous, ask the student for clarification.
   - If you do not know something, state honestly that you do not know.
6. FORMATTING:
   - Use Markdown for readability: bold keywords, bullet points, numbered steps.
   - Format equations cleanly.
   - Keep paragraphs concise.
   - End with a friendly, encouragement or a quick question to test understanding when appropriate.`;
}

// CORS Headers helper
function getCorsHeaders(req: Request) {
  const origin = req.headers.get("origin") || "*";
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Max-Age": "86400",
  };
}

serve(async (req: Request) => {
  const corsHeaders = getCorsHeaders(req);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed. Use POST." }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    if (!GEMINI_API_KEY) {
      console.error("Missing GEMINI_API_KEY environment variable.");
      return new Response(
        JSON.stringify({ error: "AI service is currently unconfigured. Please set GEMINI_API_KEY." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse and validate request
    const bodyText = await req.text();
    if (bodyText.length > 32 * 1024) {
      return new Response(
        JSON.stringify({ error: "Request payload too large (max 32KB)." }),
        { status: 413, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let payload;
    try {
      payload = JSON.parse(bodyText);
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid JSON payload." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const {
      message,
      history = [],
      language = "en",
      educationLevel = "high",
      subject = "ask_anything",
    } = payload;

    if (!message || typeof message !== "string" || message.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "Message field is required and must not be empty." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (message.length > 4000) {
      return new Response(
        JSON.stringify({ error: "Message exceeds maximum length of 4000 characters." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Build system instructions
    const systemPrompt = buildSystemPrompt(language, educationLevel, subject);

    // Format history for Gemini API
    const formattedContents = [];

    // Add conversation history (up to last 10 messages for context)
    const recentHistory = Array.isArray(history) ? history.slice(-10) : [];
    for (const item of recentHistory) {
      if (item && item.role && item.parts && Array.isArray(item.parts)) {
        const geminiRole = item.role === "user" ? "user" : "model";
        formattedContents.push({
          role: geminiRole,
          parts: item.parts.map((p: { text?: string }) => ({ text: String(p.text || "") })),
        });
      }
    }

    // Add current user message
    formattedContents.push({
      role: "user",
      parts: [{ text: message.trim() }],
    });

    // Call Gemini API
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

    const geminiResponse = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: formattedContents,
        systemInstruction: {
          parts: [{ text: systemPrompt }],
        },
        generationConfig: {
          temperature: 0.7,
          topP: 0.95,
          maxOutputTokens: 2048,
        },
        safetySettings: [
          { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
          { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
          { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
          { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
        ],
      }),
    });

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text();
      console.error(`Gemini API error [${geminiResponse.status}]:`, errorText);

      if (geminiResponse.status === 429) {
        return new Response(
          JSON.stringify({ error: "Gemini API rate limit reached. Please wait a moment and try again." }),
          { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({ error: "Failed to communicate with AI model. Please try again." }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const geminiData = await geminiResponse.json();
    const candidate = geminiData.candidates?.[0];
    const replyText = candidate?.content?.parts?.[0]?.text;

    if (!replyText) {
      const finishReason = candidate?.finishReason;
      if (finishReason === "SAFETY") {
        return new Response(
          JSON.stringify({
            reply: language === "ur"
              ? "معذرت، میں حفاظت کے اصولوں کی وجہ سے اس سوال کا جواب نہیں دے سکتا۔ براہ کرم کوئی اور تعلیمی سوال پوچھیں۔"
              : language === "ps"
                ? "بخښنه، زه د خوندیتوب مقرراتو له امله د دې پوښتنې ځواب نشم ویلای. مهرباني وکړئ بله تعلیمي پوښتنه وکړئ."
                : "I apologize, but I cannot answer that request due to educational safety guidelines. Please ask another educational question.",
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({ error: "Empty response received from AI model." }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ reply: replyText }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Unhandled error in gemini-chat:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error occurred." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
