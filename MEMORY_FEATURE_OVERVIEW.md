# Memory Feature Overview

This document describes the end-to-end "记忆功能" implementation that powers long-term personalization inside CogiTap.

## Architecture Snapshot
- **Data Models**
  - `MemoryRecord`: Stores memory text, timestamps, and an optional `conversationId` used when cross-chat sharing is disabled.
  - `MemoryConfig`: Persists feature toggles (`isMemoryEnabled`, `isCrossChatEnabled`) and tracks last update time.
- **Persistence**
  - Both models are registered with the shared `ModelContainer` in `CogiTapApp.swift` and stored via SwiftData.
  - Configuration for tokenization/synonyms/stop-words lives in `Resources/memory_config.json` and is loaded at runtime.
- **Services**
  - `MemoryService` centralizes CRUD plus scoring logic, configuration hydration, duplicate detection, and bulk clear helpers.
  - `MemoryToolBuilder` produces function-calling tool payloads based on current config and localization requirements.
- **Chat Flow Integration**
  - `ChatService` injects memory snippets into the system prompt, enables OpenAI-style tools, handles SSE tool-call decoding, executes local memory mutations, and loops until a final assistant reply is produced.
- **UI Layer**
  - `MemoryManagementView` provides list/search/edit/clear toggles with confirmation, and wiring into Settings.

## MemoryService Details
- **Saving**
  - Normalizes text, skips empties, and short-circuits when memory is disabled.
  - Duplicate detection uses case-insensitive equality and edit distance (`<= 2`) within the relevant scope (global when cross-chat is on, per-conversation otherwise).
  - Persists `conversationId` when cross-chat is disabled to keep memories session-local.
- **Retrieval**
  - Splits queries on `;`, tokenizes via configurable stop-word and character sets, and applies a multi-stage scoring system (complete > edit-distance > synonym > character overlap) with mutual exclusivity to prevent overweighting.
  - Filter rules honour cross-chat toggle: only conversation-scoped memories are returned when cross-chat sharing is off.
  - Results are sorted by score then freshness, joined with double newlines to feed the system prompt or tool replies.
- **Updating & Clearing**
  - Updates require exact original text matches and refresh timestamps; duplicates of the original are handled in-place.
  - `clearAllMemories` deletes every record and returns a count; callers reset config defaults afterwards.
- **Configuration Loading**
  - `memory_config.json` defines stop words, stop characters, and synonym groups; a fallback empty config keeps the system resilient if the file is missing.
  - Synonym groups are materialized into a bi-directional lookup table.

## Function Calling Integration
- **Unified Structures**
  - `UnifiedMessage` gained optional `toolCalls` and `toolCallId` fields; `UnifiedChatRequest` now carries `functionTools` and a `ToolChoice` enum; `StreamChunk` transports tool-call deltas; `UnifiedChatResponse` exposes parsed tool calls for non-streaming flows.
- **Tool Definitions**
  - `MemoryToolBuilder` emits three functions (`save_memory`, `retrieve_memory`, `update_memory`) with bilingual descriptions and strict parameter schemas whenever the memory feature is enabled and the provider supports OpenAI-compatible tools.
- **OpenAI Adapter Updates**
  - Requests include `tools` payloads, assistant/tool-call messages serialize `tool_calls` arrays, and streaming chunks extract incremental function metadata.
  - Full responses capture final `tool_calls` for non-streaming scenarios.
- **ChatService Loop**
  - Builds requests with system-prompt memory injection using the latest user utterance as keywords.
  - Detects streaming tool calls, surfaces status text (`正在记忆...` etc.), buffers argument segments, and short-circuits message streaming until follow-up calls finish.
  - Executes memory operations locally, persists assistant/tool messages, and re-issues model requests until no further tool calls are returned.
  - Tool messages with role `tool` are hidden from the chat transcript (`MessageListView` filters them out) but remain in history for the next API call.
  - The service gracefully falls back to plain messaging when providers lack tool support or the memory feature is disabled.

## UI Surface
- **Settings Entry Point**
  - `SettingsView` now links to the dedicated "记忆管理" screen.
- **MemoryManagementView**
  - Displays memories sorted by freshness, supports live search (case-insensitive substring), swipe-to-delete, tap-to-edit, and a bottom-bar destructive clear action with confirmation that also resets config toggles to defaults.
  - Toggle section binds directly to `MemoryConfig`, providing live control over the memory feature and cross-chat sharing.
  - `MemoryEditorView` handles both creation and editing; creation funnels through `MemoryService.saveMemory`, while edits mutate the bound record and refresh timestamps.
- **Chat Transcript**
  - `MessageListView` omits tool/system messages; `MessageBubbleView` adds a lightweight visual treatment for tool feedback should it ever surface.

## Behavioral Notes & Limitations
- The duplicate threshold of two edit operations is tuned for concise memories; adjust `MemoryService.editDistanceBetween` callers if longer-form tolerance is required.
- When cross-chat sharing is disabled, only memories saved within the active conversation participate in retrieval; existing global memories are intentionally ignored in that mode.
- Manual creation via MemoryManagementView always stores global memories (no conversation context); those will only be surfaced while cross-chat sharing is enabled.
- The current implementation processes only the first tool call per response cycle; extend `handleToolCalls` if multi-tool sequences become necessary.
- Streaming follow-up requests reuse the initial assistant placeholder message to avoid UI flicker while tools run.

## Developer Operations
- Resource tweaks (stop words, synonyms) live in `Resources/memory_config.json`; ship updates with the app—runtime edits are not supported.
- `xcodebuild -project CogiTap.xcodeproj -scheme CogiTap ...` currently fails in this environment because CoreSimulator services are unavailable; rerun locally where simulator access is permitted to validate builds.
- Keep the schema in `CogiTapApp.swift` in sync if additional SwiftData models are introduced; memory records/config must remain registered.

For outstanding questions or refinements (multi-tool support, manual conversation scoping in the editor, richer UI chrome), see the discussion in the issue tracker or extend the service/view layers noted above.
