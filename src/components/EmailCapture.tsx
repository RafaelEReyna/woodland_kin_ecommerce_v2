import { useState } from "react";

export default function EmailCapture() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!email) return;

    setStatus("loading");
    try {
      const res = await fetch("/.netlify/functions/subscribe-email", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      if (res.ok) {
        setStatus("success");
        setEmail("");
      } else {
        setStatus("error");
      }
    } catch {
      setStatus("error");
    }
  }

  if (status === "success") {
    return (
      <p className="text-sm text-[var(--color-accent)]">
        Welcome to the Kin! Check your inbox.
      </p>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col sm:flex-row gap-3 max-w-md mx-auto">
      <label htmlFor="email-capture" className="sr-only">Email address</label>
      <input
        id="email-capture"
        type="email"
        autoComplete="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="your@email.com"
        required
        className="flex-1 px-4 py-3 rounded border text-base sm:text-sm"
        style={{
          backgroundColor: "var(--color-bg)",
          borderColor: "color-mix(in srgb, var(--color-text-muted) 30%, transparent)",
          color: "var(--color-text)",
        }}
      />
      <button
        type="submit"
        disabled={status === "loading"}
        className="px-6 py-3 text-sm font-medium rounded hover:opacity-90 transition-opacity disabled:opacity-50"
        style={{
          backgroundColor: "var(--color-accent)",
          color: "var(--color-bg)",
        }}
      >
        {status === "loading" ? "Subscribing..." : "Subscribe"}
      </button>
      {status === "error" && (
        <p className="text-red-500 text-xs mt-1 sm:mt-0 sm:self-center">Something went wrong.</p>
      )}
    </form>
  );
}
