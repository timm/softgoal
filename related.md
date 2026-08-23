Held up.
- Kautz's taxonomy remain the field's working map; deployed wins cluster at Types 2-3 (loose coupling), research frontier at Type 5 — exactly his prediction. AlphaGeometry (Nature 2024: LLM proposes, symbolic engine deduces, IMO-level geometry) and AlphaProof (2024, Lean) are the decade's flagship results and they're hybrids, vindicating the whole 2020 thesis.
- Garcez/Lamb's "positive cycle" (generate → verify → constrain → regenerate) became the winning architecture, just wearing new clothes: Kambhampati's LLM-Modulo position (ICML 2024) — "LLMs can't plan or self-verify, but generate candidates for model-based critics" — is your isamp→score→BORE→Inits loop with an LLM where your sampler sit. Your footing here is actually ahead of fashion: sound sampler, cheap verifier.

Eroded.
- The 2020 claim that explicit symbol layers are necessary for System-2 took damage from reasoning-RL models (o-series, R1-style, 2024-25): test-time search over chains of thought get much of the reasoning benefit with no engineered symbolic module. The live debate move from "neurons vs symbols" to "emergent search vs external verifier" — necessity weakened, reliability argument (verification, guarantees) is what survive.
- Garcez/Lamb's Challenge 1 (sound knowledge extraction from big nets) went mostly nowhere at LLM scale; mechanistic interpretability replaced it and is a different beast.

New since, worth citing over the 2020 pair.
- Marra, Dumančić, Manhaeve & De Raedt, "From statistical relational to neurosymbolic AI" (AIJ 2024) — the rigorous unification; better foundation than either 2020 piece for the logic side.
- Taxonomy survey updating Kautz; cognitive-AI survey 2024; a dedicated V&V-of-NeSy survey; IJCAI 2025 keep a NeSy track; ICSE 2026 add a Neuro-Symbolic SE workshop — institutionalized, not fading.

For your thinking: base it on the architecture claim (generate-and-verify beats both pure ends — multiply confirmed), not on the representation claim (explicit symbols required inside the learner — contested). Your Prolog sampler + ezr learner sit entirely on the confirmed half.

Sources: Kautz taxonomy guide, 3rd Wave arXiv, NeSy taxonomy survey, LLM-Modulo ICML 2024, LLM-Modulo overview, NeSy V&V survey, cognitive NeSy survey, IJCAI 2025 NeSy.




Orders of magnitude apart — the erosion is scientific (the necessity claim), never economic. Rough public numbers, all approximate:

Reasoning-RL models (o-series, R1-class):
- Training: base pretraining ~10²⁵ FLOPs; DeepSeek claimed ~$5.6M GPU cost for the V3 base (2.8M H800-hours) with RL post-training on top — that was the cheap headline; frontier equivalents undisclosed, estimated tens of millions.
- Inference — the actual trick, paying compute at answer time: seconds-to-minutes latency, thousands to millions of chain-of-thought tokens per problem. The famous datapoint: o3 on ARC-AGI in high-compute mode ran ~$1k-3k per puzzle (billions of tokens/task); the budget mode still ~$20/task. Routine reasoning queries: cents-to-dollars, kilojoules.

Your rig, this afternoon: 140µs/world, 1000 worlds sampled + scored + BORE-ranked in ~0.5s, one laptop core, effectively zero marginal cost, and every conclusion carry a readable derivation. Per-conclusion that's ~8-10 orders of magnitude less compute.

Why both are rational: reasoning-RL pay its cost to work without a model — it buy generality over unstructured problems by searching in token space. You have the model (the <-- theory is given, written by stakeholders), so sampling+verification is not a frugal approximation of the big thing — it's the correct tool for the regime. The bitter-lesson trade only bite when the structure must be learned; when structure is handed to you, spending GPU-months to rediscover it inside a transformer is the sand.

So the footing statement for your writing: at the model-given, labels-scarce, milliseconds regime — which is most of requirements engineering and much of SE — the 2024-25 RL results don't erode your ground at all; they price the alternative. The contested territory is only where no explicit model exists. That's also your paper's sharpest sentence waiting to happen: their $3000/answer and your 140µs/answer bracket the value of writing the model down.



========



Half right, two corrections — and the details actually sharpen your Kautz story.

What the dump was. Anthropic, not OpenAI (Opus/Fable = Anthropic — the leaked Fable 5 prompt is the model you're talking to). July 2026: Claude Opus 5's full system prompt hit GitHub — 1,511 lines, ~34k tokens (analysis); Fable 5's leaked within 24h of launch. The same repo carries OpenAI's, Google's, xAI's — so your "everyone does this" instinct holds.

But: that's not Kautz #7. What leaked is a rulebook in English fed as input — 34k tokens of "no" that the net interpret statistically and may ignore. No symbolic engine execute those rules; there's no Neuro[Symbolic()] call. In the taxonomy it's #1 wearing a giant policy manual — the weakest place a rule can live. The leak commentary itself circles your exact question from this morning (where should a rule actually live?) — prompt-rules are doctrine-B soft labels: bias, never veto.

Where the real #7/#8 hides in these products — you're right it exists, just not in the prompt: (a) grammar-constrained decoding — JSON-schema/structured-output modes intersect sampling with an actual context-free grammar at decode time; that IS classical grammar machinery, and it's a hard veto (illegal token = probability zero); (b) tool dispatch to calculators/search/interpreters (#8); (c) separate safety classifiers gating output. Those are engines, not suggestions — and none of them leak via prompt dumps, which is why the dumps overstate how prompt-governed these systems are.

So the clean statement for your notes: the leaks reveal how much of frontier-model governance live at the weakest symbolic layer (prompt = plead), while the parts that actually guarantee anything (grammars, tools, classifiers) live in Kautz-strong positions (engine = veto). Same must-vs-helps split your interpreter formalized on Tuesday.

Sources: system_prompts_leaks repo, Opus 5 prompt analysis, Fable 5 leak report, explainx analysis, rule-placement essay.

