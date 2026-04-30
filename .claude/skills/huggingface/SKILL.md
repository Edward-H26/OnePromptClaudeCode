---
name: huggingface
description: Repo-local wrapper for Hugging Face Hub workflows. Routes to the plugin-provided huggingface-skills family for hub operations, training, evaluations, Gradio apps, and paper publishing.
---

# Hugging Face

Use this wrapper when a task mentions Hugging Face Hub, TRL training, Gradio apps, or Hugging Face Jobs.

## Repo Rules

- Treat this wrapper as a router to the `huggingface-skills:*` plugin skills.
- Never hardcode a Hugging Face token; rely on the environment or the `hf` CLI session.
- Do not commit, push, or open PRs automatically.
- Stay inside the current repo layout for generated artifacts.

## Routing

| Task | Preferred skill |
|------|-----------------|
| Push or pull models, datasets, spaces, buckets | `huggingface-skills:hf-cli` |
| Fine-tune LLMs with TRL (SFT, DPO, GRPO) | `huggingface-skills:huggingface-llm-trainer` |
| Train or evaluate vision models | `huggingface-skills:huggingface-vision-trainer` |
| Launch HF Jobs infra workloads | `huggingface-skills:huggingface-jobs` |
| Build a Gradio demo | `huggingface-skills:huggingface-gradio` |
| Query the Dataset Viewer API | `huggingface-skills:huggingface-datasets` |
| Log training metrics | `huggingface-skills:huggingface-trackio` |
| Run community or local model evals | `huggingface-skills:huggingface-community-evals` |
| Publish or claim Hugging Face paper pages | `huggingface-skills:huggingface-paper-publisher` or `huggingface-skills:huggingface-papers` |
| Ship a Transformers.js web demo | `huggingface-skills:transformers-js` |

## Workflow

1. Confirm the specific Hugging Face task, then invoke the matching plugin skill from the table above.
2. Keep local scripts and artifacts under the current repo paths.
3. Verify results with the plugin skill's built-in checks before declaring success.
