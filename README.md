# Multi-Agent Research Assistant

An n8n LangChain workflow that researches a topic, searches OpenAlex for academic papers, summarizes the selected papers, compares them, proposes a testable hypothesis, and produces a downloadable markdown report.

The source workflow is:

`workflows/Multi-Agent Research Assistant (MVP) - LangChain (1).json`

## What This Project Contains

- `workflows/` - the importable n8n workflow JSON.
- `reports/.gitkeep` - placeholder output folder. The current workflow does not write here automatically.
- `.env.example` - environment settings used by Docker or `start-n8n.sh`.
- `start-n8n.sh` - optional local n8n launcher if n8n is installed on your machine.
- `README.md` - setup and run instructions.

## Workflow Shape

```text
Research Form
  -> Literature Agent
  -> Normalize Literature Results
  -> Summarization Agent
  -> Parse Summary
  -> Aggregate Summaries
  -> Comparison Agent1 -> Parse Comparison
  -> Hypothesis Agent1 -> Parse Hypothesis
  -> Merge Agent Results
  -> Build Report
```

`Build Report` is the final node. It creates a markdown file as binary output named like:

```text
report-2026-06-03-your-topic.md
```

Download that file directly from the `Build Report` node output in n8n.

## Requirements

- Docker Desktop.
- An OpenRouter account and API key.
- This project folder on your machine.

The workflow uses OpenRouter Chat Model nodes with:

```text
openrouter/free
```

That lets OpenRouter choose an available free model for the request.

## 1. Prepare The Environment File

From the project root:

```bash
cd /Users/syedanoorain/Downloads/research-multi-agent
cp .env.example .env
```

You do not need to put the OpenRouter key in `.env`. n8n stores that key as a credential in the UI.

## 2. Start n8n With Docker

Create a persistent Docker volume for n8n data:

```bash
docker volume create n8n_data
```

Start n8n:

```bash
docker run -d --name research-n8n \
  -p 5678:5678 \
  --env-file .env \
  -e N8N_BLOCK_ENV_ACCESS_IN_NODE=false \
  -e N8N_RUNNERS_ENABLED=true \
  -e N8N_SECURE_COOKIE=false \
  -v n8n_data:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n:latest
```

Watch the logs until n8n is ready:

```bash
docker logs -f research-n8n
```

Open n8n:

```text
http://localhost:5678
```

On first launch, n8n will ask you to create a local owner account. This account is for your local n8n instance.

## 3. Import The Workflow

1. Open `http://localhost:5678`.
2. Go to **Workflows**.
3. Choose **Import from File**.
4. Select:

```text
workflows/Multi-Agent Research Assistant (MVP) - LangChain (1).json
```

5. Open the imported workflow.

## 4. Add OpenRouter Credentials

1. In n8n, open any **OpenRouter Chat Model** node.
2. In **Credential for OpenRouter API**, create a new credential.
3. Paste your OpenRouter API key.
4. Save the credential.
5. Select the same credential for all four model nodes:
   - `OpenRouter Chat Model`
   - `OpenRouter Chat Model1`
   - `OpenRouter Chat Model2`
   - `OpenRouter Chat Model3`

Leave the model value as:

```text
openrouter/free
```

Save the workflow after assigning credentials.

## 5. Run A Test

Start small first:

1. Click the **Research Form** node.
2. Click **Execute step**.
3. n8n will show a form URL.
4. Open the form URL in your browser.
5. Enter a topic, for example:

```text
multi-agent systems for smart agriculture
```

6. Set **Max papers** to `1` for the first test.
7. Submit the form.
8. Wait for the workflow execution to finish.

After the first successful test, increase **Max papers** to `3` or `5`.

## 6. Download The Report

The workflow does not use a final file-write node.

To download the report:

1. Open the finished execution in n8n.
2. Click the final **Build Report** node.
3. Open its output panel.
4. Look for the binary output named `data`.
5. Download the markdown file from that binary output.

The downloaded file will use the generated report filename shown in the node JSON output.

## Docker Commands

Check running containers:

```bash
docker ps
```

View n8n logs:

```bash
docker logs -f research-n8n
```

Stop n8n:

```bash
docker stop research-n8n
```

Start it again:

```bash
docker start research-n8n
```

Remove the container:

```bash
docker rm research-n8n
```

If the container name already exists and you want a fresh container:

```bash
docker rm -f research-n8n
```

Then rerun the Docker start command from step 2.

## Optional Local n8n

If you have `n8n` installed globally, you can run:

```bash
./start-n8n.sh
```

This loads `.env`, keeps local n8n data in `.n8n/`, and starts n8n at:

```text
http://localhost:5678
```

Docker is the recommended path for checking the project.

## Troubleshooting

- **Provider returned error / Service unavailable:** `openrouter/free` depends on currently available free models. Wait a bit and run again, or choose a specific OpenRouter model in each Chat Model node.
- **Credential error:** reselect your OpenRouter credential on all four OpenRouter Chat Model nodes.
- **No useful papers returned:** try a more specific topic and run with `Max papers = 1`.
- **JSON parse error:** reduce `Max papers`, then rerun. Free models can occasionally return text around the JSON.
- **No file in `reports/`:** expected. The final report is downloaded from the `Build Report` node output, not written to disk.
