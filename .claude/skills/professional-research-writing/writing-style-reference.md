# Professional Research Writing Skill

## Overview

This skill defines the writing style for generating professional research content that mirrors the style of an accomplished research scientist with publications in top-tier venues (CVPR, ICML, ACM, etc.). The writing maintains academic rigor while remaining accessible and natural, with clear logical flow and human-like readability.

## Core Principles

### 1. Voice and Tone
- **Professional Authority**: Write with confidence backed by evidence. Make definitive statements when appropriate rather than hedging unnecessarily.
- **Direct Expression**: Use active voice and clear subject-verb-object construction. Avoid excessive passive constructions.
- **Natural Flow**: Write as a knowledgeable colleague would explain concepts. Balance formality with readability.
- **Objective Clarity**: Present facts and findings objectively while maintaining engagement through clear explanations.

### 2. Sentence Structure

**Participial Phrase Placement**
- ✅ ACCEPTABLE: Participial phrases at the BEGINNING of sentences
  - "Building on these findings, we manually adjust the layer weightings..."
  - "By evaluating Google's pre-trained model, we notice significant impacts..."
  - "By matching local patterns or textures between the style and content features, traditional algorithms work well..."

- ❌ AVOID: Participial phrases in the MIDDLE or END of sentences
  - AVOID: "We adjust the weightings, building on these findings, and compare outputs."
  - AVOID: "Traditional algorithms work well, matching local patterns between features."
  - PREFER: "We build on these findings and adjust the weightings to compare outputs."
  - PREFER: "Traditional algorithms match local patterns between features and work well for rich textures."

**Varied Sentence Length**
- Mix short, punchy sentences with longer, complex ones
- Short sentences emphasize key points: "This trend underscores the appeal of neural style transfer techniques."
- Longer sentences explain relationships: "By matching local patterns or textures between the style and content features, traditional algorithms work well when the style image provides rich textures or strokes the content."

**Strong Declarative Statements**
- Lead with clear assertions: "We propose a new approach to neural style transfer that better handles abstract and non-figurative style references."
- Follow with supporting details and evidence
- Use compound sentences to connect related ideas: "Our approach aims to preserve the global structure of the content image while transferring the global color distribution of the style image where the output retains the content image's structures with the style image's overall color palette, tone, and mood."

### 3. Paragraph Construction

**Topic Sentences**
- Begin each paragraph with a clear statement of its main idea
- Example: "However, alongside the excitement, this trend also exposed fundamental limitations of traditional style transfer methods."

**Logical Development**
- Present ideas in logical sequence
- Each sentence builds upon or clarifies the previous one
- Conclude paragraphs with implications or transitions to next ideas

**Transitions Between Paragraphs**
- Use transitional phrases strategically: "However," "Additionally," "Furthermore," "In contrast," "As a result"
- Create bridges between sections that maintain narrative flow
- Example: "However, these tools focus on quantitative data, which often do not capture the deeper, contextual aspects of viewer behavior."

### 4. Technical Writing Elements

**Precision in Terminology**
- Use exact technical terms consistently
- Define specialized terms on first use when necessary
- Maintain consistency in naming conventions (e.g., if you call something "dimension-value framework," use this exact phrase throughout)

**Quantitative Support**
- Include specific numbers and metrics: "Average 5 dimensions (min=4, max=6)"
- Present statistical results clearly: "M = 4.55/5" or "p < .05"
- Use tables for comparative data when appropriate

**Methodology Description**
- Describe methods clearly and completely
- Structure implementation details logically: frameworks used → hardware setup → external resources
- Example: "This project is implemented in Python by utilizing both the PyTorch and TensorFlow frameworks to compare baseline models and our proposed neural style transfer architecture."

**Results Presentation**
- State findings directly with supporting evidence
- Compare results across conditions when relevant
- Acknowledge both strengths and limitations

### 5. Structural Organization

**Section Hierarchy**
```
1 Main Section Title
1.1 Subsection Title
1.1.1 Sub-subsection Title (if needed)
```

**Standard Research Paper Sections**
- Motivation/Introduction: Establish context and problem
- Approach/Method: Describe solution strategy
- Implementation Details: Technical specifics
- Results/Evaluation: Findings with evidence
- Discussion: Interpretation and implications
- Limitations: Honest assessment of constraints

**Within-Section Organization**
- Use descriptive subheadings that clearly indicate content
- Group related information together
- Progress from general concepts to specific details

### 6. Narrative Flow Patterns

**Motivation Sections**
- Start with broad context (trends, current practices)
- Identify limitations or gaps
- Propose your approach
- Explain implications and applications
- Example pattern: "In recent years, [trend]... However, [limitation]... We propose [solution]... This would enable [applications]..."

**Approach Sections**
- Describe what you observe or analyze
- Explain your reasoning process
- Detail your methodology
- Connect back to addressing the identified problems

**Results Sections**
- Present findings systematically
- Use subheadings to organize different aspects
- Support claims with quantitative and qualitative evidence
- Compare with baselines when applicable

### 7. Language Conventions

**Verb Tense Usage**
- Present tense for general truths: "The pipeline uses GPT-4 to generate dimensions..."
- Past tense for specific actions taken: "We conducted semi-structured interviews..."
- Present perfect for results with ongoing relevance: "Our formative study has confirmed..."

**Person and Voice**
- Use "we" for actions you/team performed: "We propose," "We evaluate," "We implement"
- Use "the system" or "the method" for describing tool capabilities: "The system must efficiently process large-scale comment data"
- Use "the user" or "creators" when describing user interactions: "Creators can chat with audience personas"

**Formal Yet Accessible Language**
- Avoid colloquialisms but don't be unnecessarily complex
- Use technical terms appropriately but explain when needed
- Example: "Proxona distills audience traits from comments into dimensions (categories) and values (attributes), then clusters them into interactive personas representing audience segments."

### 8. Evidence and Support

**Citation Patterns**
- Reference prior work naturally: "as exemplified by the viral 'Studio Ghibli' trend"
- Cite methods formally: "(Gatys et al., 2016)"
- Ground claims in evidence from your work

**Examples and Illustrations**
- Use concrete examples to clarify abstract concepts
- Example: "For example, if you want to fetch the documents at https://docs.google.com/document/d/..."
- Provide context for technical details when helpful

**Comparative Analysis**
- Compare your approach with baselines or alternatives
- Highlight advantages and acknowledge tradeoffs
- Example: "Proxona showed higher audience similarity: M = 6.4/10 clusters"

### 9. Discussion and Implications

**Balanced Assessment**
- Acknowledge both strengths and limitations honestly
- Discuss practical implications of findings
- Suggest future directions based on current work

**Forward-Looking Perspective**
- Connect current work to broader goals
- Identify opportunities for extension
- Frame limitations as opportunities for future research

### 10. Common Patterns to Follow

**Introducing Problems**
"However, [existing approach] has limitations. [Describe specific limitation]. Without [missing element], [consequence]."

**Proposing Solutions**
"We propose [solution] that [key capability]. Our approach aims to [goal] by [mechanism]."

**Describing Implementation**
"[Component] is implemented in [technology] by utilizing [frameworks/tools]. We use [specific tool] to [specific purpose]."

**Presenting Results**
"[Finding] demonstrates [implication]. Through [evaluation method], we show that [specific result with metrics]."

**Acknowledging Limitations**
"While [approach] provides [benefits], [limitation] remains. Future work could address this by [potential solution]."

## Specific Guidelines for Different Content Types

### Research Papers
- Follow standard IMRaD structure (Introduction, Methods, Results, Discussion)
- Include clear motivation and problem statement
- Provide comprehensive methodology
- Support all claims with evidence
- Discuss limitations and future work

### Technical Documentation
- Begin with clear overview of purpose
- Organize by functionality or components
- Include concrete examples and code snippets when relevant
- Provide step-by-step instructions where appropriate
- Use consistent terminology throughout

### Literature Reviews/Summaries
- Identify main contributions clearly
- Explain methodological approaches
- Highlight key findings with supporting data
- Compare and contrast different approaches
- Synthesize implications across studies

### Proposals and Abstracts
- State the problem concisely
- Describe your approach and its novelty
- Highlight expected contributions
- Maintain focus on significance and impact

## Quality Checklist

Before finalizing any written content, verify:

- [ ] Participial phrases appear only at sentence beginnings, never in middle or end
- [ ] Used active voice for main actions
- [ ] Varied sentence length appropriately
- [ ] Included clear topic sentences for each paragraph
- [ ] Maintained logical flow between paragraphs and sections
- [ ] Used precise technical terminology consistently
- [ ] Supported claims with evidence (quantitative or qualitative)
- [ ] Organized content with clear hierarchy
- [ ] Included concrete examples where helpful
- [ ] Maintained professional yet accessible tone
- [ ] Ensured smooth transitions between ideas
- [ ] Verified that writing sounds natural and human-like

## Example Transformations

### Participial Phrase Placement:

**✅ CORRECT (at beginning):**
"By utilizing TensorFlow and TensorFlow Hub, we explored traditional neural style transfer architecture."

**❌ INCORRECT (in middle):**
"We explored, utilizing TensorFlow and TensorFlow Hub, traditional neural style transfer architecture."

**✅ CORRECT (restructured):**
"We utilized TensorFlow and TensorFlow Hub to explore traditional neural style transfer architecture."

---

### Before (weak structure):
"The model has limitations. It can't preserve straight lines well."

### After (stronger structure):
"After running several trials, we realize that existing models have limited capabilities in preserving straight lines and boundaries inside content."

---

### Before (overly passive):
"It was found that property graphs are perfect at representing complex relationships."

### After (more direct):
"The experiment reveals that property graphs are perfect at representing complex relationships through nodes and edges."

---

### Before (participial phrase in wrong position):
"Traditional algorithms work well, matching local patterns between features, when textures are rich."

### After (correctly positioned):
"By matching local patterns between features, traditional algorithms work well when textures are rich."

---

## Application Notes

- This style prioritizes clarity and directness while maintaining academic rigor
- The writing should sound like a knowledgeable colleague explaining their work
- Natural flow takes precedence over rigid formality
- Evidence and precision are essential, but accessibility matters
- Each piece should stand as a complete, well-organized unit of thought
- Participial phrases can provide elegant sentence openings but must be placed at the beginning only