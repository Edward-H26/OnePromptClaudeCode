---
name: professional-research-writing
description: Professional research writing style for all written content. Use when writing research papers, technical documentation, literature reviews, academic content, README files, explanations, or any text generation. Enforces clarity, natural flow, evidence-based claims, participial phrase placement rules, and human-like readability. CRITICAL priority skill - always active for all writing tasks. Covers sentence construction, paragraph structure, methodology descriptions, results presentation, and quality checklists.
---

# Professional Research Writing Skill

## Purpose

Define the professional research writing style for an accomplished research scientist with publications in top-tier venues (CVPR, ICML, ACM, CHI). The style emphasizes clarity, natural flow, evidence-based claims, and human-like readability while maintaining academic rigor.

**Key Characteristics:**
- Direct, active voice with clear subject-verb-object construction
- Participial phrases ONLY at sentence beginnings (never middle/end)
- Natural, flowing prose that sounds like a knowledgeable colleague
- Evidence-backed claims with precise quantitative support
- Logical paragraph structure with clear topic sentences

## When to Use This Skill

Automatically activates when:
- Writing any text content (research papers, documentation, explanations)
- Creating or editing markdown files
- Generating README files
- Writing technical descriptions
- Composing paragraphs or sections of any kind
- Any text generation task

**Note:** This skill is configured with CRITICAL priority and `alwaysActive: true` in skill-rules.json.

---

## Core Writing Principles

### 1. Participial Phrase Rules (CRITICAL)

**ACCEPTABLE: Beginning of sentence only**
```
"By evaluating Google's pre-trained Neural style transfer model with a Picasso painting 
as the style image and a skyline as the content image, we notice the model's convolutional 
layers have significant impacts to the stylization process."

"By matching local patterns or textures between the style and content features, traditional 
algorithms work well when the style image provides rich textures or strokes the content."

"Building on these findings, we manually adjust the layer weightings and compare the 
outputs across different configurations."
```

**NEVER: Middle or end of sentence**
```
WRONG: "We notice, by evaluating the model, significant impacts..."
WRONG: "Traditional algorithms work well, matching local patterns between features."
WRONG: "We adjust the weightings, building on these findings, and compare outputs."

CORRECT: "We evaluate the model and notice significant impacts..."
CORRECT: "Traditional algorithms match local patterns and work well for rich textures."
CORRECT: "We build on these findings and adjust the weightings to compare outputs."
```

### 2. Sentence Construction Patterns

**Pattern A: Strong Declarative Opening**
```
"We propose a new approach to neural style transfer that better handles the abstract 
and non-figurative style references."

"This research paper presents three direct mappings for transforming RDF databases 
into property graph databases in order to address fundamental challenges in graph 
database interoperability."

"We present Proxona, an LLM-powered system that transforms static audience comments 
into interactive, multi-dimensional personas."
```

**Pattern B: Problem-Solution Structure**
```
"However, alongside the excitement, this trend also exposed fundamental limitations 
of traditional style transfer methods. We observed that applying a highly abstract 
art style to a photographic image can yield distorted and incoherent outputs."

"However, these tools focus on quantitative data, which often do not capture the 
deeper, contextual aspects of viewer behavior, such as motivations or preferences."
```

**Pattern C: Compound Sentences with Clear Connections**
```
"Our approach aims to preserve the global structure of the content image while 
transferring the global color distribution of the style image where the output 
retains the content image's structures with the style image's overall color palette, 
tone, and mood."

"The simple database mapping transforms schema less RDF databases into property 
graphs without considering schema restrictions, which makes it suitable for datasets 
where each resource defines its resource class."
```

### 3. Paragraph Structure

**Opening Topic Sentence:**
```
"In recent years, AI driven image stylization has captivated broad audiences as 
exemplified by the viral 'Studio Ghibli' trend on social media, where everyday 
photographs were stylized with the vivid colors and detailed textures from Studio 
Ghibli's animated films."

"All interviewees unanimously agreed on the importance of understanding their audience."

"The paper addresses several challenges in the current graph database ecosystems."
```

**Development with Supporting Details:**
```
"By matching local patterns or textures between the style and content features, 
traditional algorithms work well when the style image provides rich textures or 
strokes the content. However, it breaks down for abstract art where no clear patch 
correspondences exist. Without discrete shapes to guide the model, patch based methods 
may introduce arbitrary noise or overly blur the output, which fails to capture the 
intended artistic effect."
```

**Concluding with Implications:**
```
"By addressing those limitations in current style transfer methods, our approach 
generates more general and reliable stylization results, which improves the toolbox 
for both digital artists and everyday content creators."

"By exploring query interoperability and developing transformations between SPARQL 
and property graph query languages, the paper builds a solid foundation for the 
research community to improve interoperability across diverse graph database 
technologies and enhance better graph based data analytics across multiple domains."
```

---

## Reference Scripts and Patterns

### Script 1: Introducing Motivation

**Template:**
```
In recent years, [context/trend]. [Specific example]. This [observation] underscores [broader significance].

However, [limitation/challenge]. [Specific evidence]. Without [missing element], [negative consequence].

We propose [solution] that [key capability]. Our approach aims to [goal] by [mechanism]. 
[Outcome description with "where" clause connecting details].

[Future implications and applications].
```

### Script 2: Describing Approach/Methodology

**Template:**
```
By [action/evaluation], we [observation/finding] since/as [explanation]. Building on 
these findings, we [next action] and [evaluation method]. We [assess/measure] using 
[metrics] to [purpose]. After [process], we realize that [insight]. To [goal], we 
[solution approach].
```

### Script 3: Implementation Details

**Template:**
```
This [project/system] is implemented in [language] by utilizing [frameworks] to [purpose]. 
We utilized [specific tool] to [specific task]. In order to [goal], we chose [technology] 
with [specific component] and additional libraries. For [aspect], we [approach/choice]. 
For [another aspect], our [element] were [details]. For [resource type], our [items] 
were obtained from [source].
```

### Script 4: Presenting Research Summaries

**Template:**
```
This research paper presents [main contribution] in order to address [challenge]. The 
researchers propose [framework/approach] to include [components] in order to address 
[limitations]. The [first component] [description and purpose], which makes it suitable 
for [use case]. The [second component] [description], which [capability]. The [third 
component] provides [description] by [mechanism], which preserves [important aspects]. 
By [evaluation method] against [criteria], this paper illustrates that [key finding].
```

### Script 5: Results and Findings

**Template:**
```
[Finding/observation] demonstrates [implication]. Through [method], we show that [specific 
result with metrics]. The [evaluation/experiment] reveals that [outcome]. [Component A] 
are perfect at [capability] through [mechanism]. Meanwhile, [Component B] provide [different 
capability] through [different mechanism]. Hence, [synthesis/conclusion].
```

### Script 6: User Study Results with Statistics

**Template:**
```
**[Category]:**

| Criterion | [Condition A] | [Condition B] | Significance |
|-----------|---------------|---------------|--------------|
| [Metric 1] (Q#) | M (SD) | M (SD) | p < .## |
| [Metric 2] (Q#) | M (SD) | M (SD) | - |

[Interpretation]: [Condition] showed [comparison] in [aspects]. [Additional context about 
specific findings]. [Key insight about what this means].
```

---

## Language and Style Guidelines

### Verb Tense Usage

**Present Tense (general truths, system capabilities):**
```
"The pipeline uses GPT-4 to generate dimensions and values."
"Traditional algorithms work well when the style image provides rich textures."
"Creators can chat with audience personas to better understand their audiences."
```

**Past Tense (specific actions taken):**
```
"We conducted semi-structured interviews with 13 YouTube creators."
"We evaluated results using style loss, content loss, and various metrics."
"The researchers employed Neo4j with rdf2pg tool to process diverse RDF datasets."
```

**Present Perfect (ongoing relevance):**
```
"Our formative study has confirmed that creators face challenges in understanding 
audience motivations."
"The researchers have proposed a comprehensive framework."
```

### Person and Voice

**"We" for researcher actions:**
```
"We propose a new approach..."
"We evaluate results using..."
"We implement this in Python..."
"We realize that existing models..."
```

**"The system/method/approach" for capabilities:**
```
"The system must efficiently process large-scale comment data."
"The approach aims to preserve the global structure."
"The method generates more general and reliable stylization results."
```

**"The user/creators/researchers" for subjects:**
```
"Creators can chat with audience personas."
"The researchers design three formally defined mappings."
"Participants found Proxona helped recognize heterogeneity."
```

### Transition Words and Phrases

**Contrast:**
```
"However, alongside the excitement, this trend also exposed..."
"Meanwhile, RDF graphs provide more semantic information..."
"In contrast, audience personas are generated by transforming unstructured..."
```

**Addition:**
```
"Additionally, with advanced algorithms and Apache Jena's StreamRDF class..."
"Furthermore, the researchers can extend these mappings..."
```

**Causation:**
```
"Hence, the paper shows that property graph databases..."
"As a result, the method avoids the distortions..."
"Since certain convolutional layers hold greater weight..."
```

**Elaboration:**
```
"For instance, I4 defined his target audience as..."
"For example, if you want to fetch the documents at..."
"To improve that, we include different edge loss functions..."
```

---

## Quality Checklist

Before finalizing written content, verify:

### Sentence-Level
- [ ] Participial phrases appear ONLY at sentence beginnings
- [ ] No participial phrases in middle or end positions
- [ ] Active voice used for main actions (we/researchers did X)
- [ ] Clear subject-verb-object structure
- [ ] Sentence length varies (mix of short and long)
- [ ] Each sentence advances the argument

### Paragraph-Level
- [ ] Clear topic sentence opens each paragraph
- [ ] Sentences flow logically from one to next
- [ ] Supporting details build on main idea
- [ ] Concluding sentence provides transition or implication
- [ ] Smooth transitions between paragraphs

### Content-Level
- [ ] Technical terms used precisely and consistently
- [ ] Claims supported with evidence (quantitative or qualitative)
- [ ] Examples provided where helpful
- [ ] Metrics include specific values (M, SD, p-values)
- [ ] Methods described completely but concisely

### Style-Level
- [ ] Professional yet accessible tone
- [ ] Natural, human-like flow
- [ ] No unnecessary hedging or overconfidence
- [ ] Appropriate formality for academic context
- [ ] Sounds like a knowledgeable colleague explaining work

---

## Usage Instructions

When generating content with this skill:

1. **Start with structure**: Determine section type (motivation, approach, results, etc.)
2. **Select appropriate script**: Choose matching template from Reference Scripts
3. **Apply writing rules**: 
   - Place participial phrases only at beginnings
   - Use active voice with "we" for actions
   - Vary sentence length
4. **Add specific content**: Fill in with technical details, metrics, findings
5. **Review against checklist**: Verify all quality criteria met
6. **Read aloud test**: Content should sound natural when read aloud

---

## Common Patterns Summary

### Opening Sentences
```
"In recent years, [trend/context]..."
"This research paper presents [contribution]..."
"We propose [solution] that [capability]..."
"By [method], we [finding]..."
"However, [limitation/challenge]..."
```

### Explaining Methods
```
"We utilize [technology] to [purpose]."
"In order to [goal], we [approach]."
"By [action], we realize that [insight]."
"Building on these findings, we [next step]."
```

### Presenting Results
```
"The experiment reveals that [finding]."
"Through [evaluation], we show that [result with metrics]."
"[System] demonstrates [capability] with [evidence]."
"Participants reported [finding] (M = X, SD = Y, p < .##)."
```

### Discussing Implications
```
"By addressing [problem], our approach [benefit], which [broader impact]."
"This enables [application] to [capability] without [constraint]."
"As one can see, [observation] demonstrates [significance]."
```

---

## Additional Resources

For detailed writing principles, additional examples, and comprehensive guidelines, refer to:
- `writing-style-reference.md` in this skill folder
