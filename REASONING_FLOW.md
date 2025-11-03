# 思维链动画流式方案说明

本文档记录了在 `ReasoningFlowView` 中实现思维链卡片“边流式、边展示”的方案，帮助之后的维护和迭代。

## 背景问题

- 原实现中，每当 `reasoningContent` 有新的 token 到来，`ReasoningFlowView` 都会被重新触发动画初始化；
- `revealedSteps` 被重置为 0，导致卡片只是在拉伸，却因始终不满足 `index < revealedSteps` 的条件而无法真正显示文字；
- 用户体验表现为框体在增长，但卡片内容一直空白。

## 解决思路

1. **区分“展示卡片”与“更新文本”**  
   - 卡片一旦出现，就保持可见；后续 token 只是在原卡片里追加文本。  
   - 拆分状态：`revealedSteps` 表示当前可见的步骤数量，`scheduledUpToStep` 记录已经安排过动画的最大步骤。

2. **首次出现时才初始化动画**  
   - 当第一次检测到思维链内容时，立即展示 Step 1；  
   - 之后只有新增的 Step 才会排入动画序列，不会把既有节点重置到隐藏状态。

3. **增量调度新增步骤**  
   - 每当解析得到更多 Step（例如从 2 变 3），只为新增部分安排 reveal 动画；  
   - 使用 `animationID` 作为轻量级“取消信号”，避免旧的调度在新会话或重置后误触发。

4. **流式文本直接绑定**  
   - Step 内的文本仍通过 SwiftUI 绑定，收到 token 即追加字符串；  
   - 因为卡片不会被重新隐藏，用户看到的是连续的“打字”效果。

## 关键实现点

- `ReasoningFlowView` 中新增状态：
  - `revealedSteps`：当前已经展示的步骤总数；
  - `scheduledUpToStep`：最新一轮动画调度覆盖的最大步骤；
  - `animationID`：用于取消旧调度。
- `handleReasoningChange` 负责对比解析结果与状态，决定是否启动新的 reveal；
- `scheduleAdditionalReveals` 只在需要时为新增步骤排动画，并在回调内校验 `animationID`；
- `resetRevealState` 仅在思维链被清空时触发，保证新一轮推理重新开始。

## 效果

- Step 1 会在首次出现时立即展示，后续 token 持续填充内容；
- 新增 Step 以设定节奏依次显现，不会因为 token 频繁到来而被重置；
- 旧 Step 保持可见，内容流式增长，视觉上更贴合大模型的推理过程。

## 后续扩展建议

- 根据模型回传的“finish_reason”等信息，微调新增 Step 的节奏；
- 在真实设备上加入轻触或震动反馈，强化关键节点到来的感知；
- 如果未来支持多层嵌套推理，可在现有状态机上扩展“层级/分支”标识。
