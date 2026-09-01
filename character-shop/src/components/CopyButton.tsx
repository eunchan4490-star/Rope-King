"use client";

import { useState } from "react";

export default function CopyButton({ value }: { value: string }) {
  const [copied, setCopied] = useState(false);

  async function handleCopy() {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      // Clipboard API can be unavailable (non-HTTPS context, permissions) —
      // the value is still visible on screen for manual copy either way.
    }
  }

  return (
    <button
      type="button"
      onClick={handleCopy}
      className="rounded bg-white/10 px-2 py-1 text-[11px] font-semibold text-white/80 hover:bg-white/20"
    >
      {copied ? "복사됨!" : "복사"}
    </button>
  );
}
