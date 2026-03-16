#!/usr/bin/env bun

import { readFileSync, writeFileSync } from "node:fs";

type Block = {
  type?: string;
  text?: string;
};

type MediaItem = {
  type?: string;
  url?: string;
};

type Tweet = {
  text?: string;
  created_timestamp: number;
  author: {
    name: string;
    screen_name: string;
  };
  article?: {
    title?: string;
    content?: {
      blocks?: Block[];
    };
  };
  media?: {
    all?: MediaItem[];
  };
};

type Payload = {
  tweet: Tweet;
};

function renderBlock(block: Block): string {
  const text = (block.text || "").trim();
  if (!text) {
    return "";
  }

  switch (block.type) {
    case "header-one":
      return `# ${text}`;
    case "header-two":
      return `## ${text}`;
    case "blockquote":
      return `> ${text}`;
    default:
      return text;
  }
}

function formatDate(timestamp: number): string {
  const date = new Date(timestamp * 1000);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function main(): void {
  if (process.argv.length !== 5) {
    throw new Error(
      "Usage: bun scripts/extract-x.ts <json-path> <source-url> <output-path>"
    );
  }

  const [, , jsonPath, sourceUrl, outputPath] = process.argv;
  const payload = JSON.parse(readFileSync(jsonPath, "utf8")) as Payload;
  const tweet = payload.tweet;
  const author = tweet.author.name;
  const username = tweet.author.screen_name;
  const createdAt = formatDate(tweet.created_timestamp);
  const article = tweet.article;
  const mediaItems = tweet.media?.all || [];

  let title: string;
  let body: string;

  if (article) {
    title = article.title || tweet.text || "X Article";
    const blocks = article.content?.blocks || [];
    body = blocks.map(renderBlock).filter(Boolean).join("\n\n");
  } else {
    title = tweet.text || "X Post";
    body = tweet.text || "";
  }

  if (!body.trim()) {
    throw new Error("Error: extracted body is empty.");
  }

  const mediaLines = mediaItems
    .filter((item) => item?.url)
    .map((item) => {
      const kind = String(item.type || "media").replace(/^./, (s) => s.toUpperCase());
      return `- ${kind}: ${item.url}`;
    });

  const safeName = title.replace(/[\\/:*?"<>|]+/g, "-").replace(/^[.\s]+|[.\s]+$/g, "");
  const filename = `${(safeName || "x-post").slice(0, 80)}.md`;

  const parts = [
    `# ${title}`,
    "",
    `**Author:** ${author} (@${username})`,
    `**Published:** ${createdAt}`,
    `**Source:** ${sourceUrl}`,
  ];

  if (mediaLines.length > 0) {
    parts.push("", "## Media", "", ...mediaLines);
  }

  parts.push("", "---", "", body.trim(), "");

  writeFileSync(filename, parts.join("\n"), "utf8");
  writeFileSync(outputPath, filename, "utf8");
}

main();
