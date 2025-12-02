from fastapi import FastAPI, Request, Form, HTTPException, APIRouter
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse, FileResponse
import requests
import json
import time
import os
import uuid
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="心情音乐生成器", version="1.0.0")

# 创建带前缀的路由器
router = APIRouter(prefix="/moodmusic")

# 静态文件挂载到带前缀的路径
app.mount("/moodmusic/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

TEMP_DIR = "temp_sessions"

def generate_music_prompt_with_llm(mood: str, api_key: str) -> dict:
    """使用 LLM 根据心情生成音乐提示词和歌词"""
    url = "https://api.minimaxi.com/v1/text/chatcompletion_v2"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": "MiniMax-Text-01",
        "max_tokens": 4096,
        "temperature": 0.7,
        "messages": [
            {
                "role": "system",
                "content": "你是音乐制作人。根据用户心情，生成音乐风格和歌词。"
                          "请严格按照 JSON 格式返回：\n"
                          "{\"prompt\": \"音乐风格描述\", \"lyrics\": \"歌词内容\"}\n\n"
                          "要求：\n"
                          "1. prompt: 30-60字，用逗号分隔。必须包含：曲风（如爵士/流行/摇滚）、人声类型（男声/女声）、乐器（如钢琴/吉他）、情绪、氛围。例如：\"爵士,男声,钢琴伴奏,忧郁,深夜酒吧\"\n"
                          "2. lyrics: 80-150字。结构完整但精炼，使用\\n分隔。必须包含：[Intro], [Verse], [Pre-Chorus], [Chorus], [Outro]。每个部分2-4行即可"
            },
            {
                "role": "user",
                "content": f"我现在的心情是：{mood}\n\n请为我创作音乐和歌词。"
            }
        ]
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload)

        # 提取 trace_id
        llm_trace_id = response.headers.get('trace-id') or response.headers.get('Trace-ID') or 'N/A'
        print(f"LLM API Trace-ID: {llm_trace_id}")

        if response.status_code != 200:
            raise Exception(f"LLM API 调用失败: {response.status_code}")

        result = response.json()
        content = result["choices"][0]["message"]["content"]

        # 尝试解析 JSON
        try:
            # 提取 JSON 部分
            json_start = content.find('{')
            json_end = content.rfind('}') + 1
            if json_start != -1 and json_end > json_start:
                json_str = content[json_start:json_end]
                data = json.loads(json_str)
                return {
                    "prompt": data.get("prompt", "流行,女声,吉他伴奏,温柔,午后阳光"),
                    "lyrics": data.get("lyrics", ""),
                    "llm_trace_id": llm_trace_id
                }
        except Exception as e:
            print(f"Failed to parse LLM response as JSON: {e}")

        # 如果解析失败，返回默认值
        return {
            "prompt": "流行,女声,吉他伴奏,温柔,午后阳光",
            "lyrics": "[Intro]\n轻轻的\n微风吹过\n[Verse]\n心情如云朵\n飘荡在天空\n[Chorus]\n音乐带走烦恼\n旋律治愈心灵\n[Outro]\n慢慢地\n找回宁静",
            "llm_trace_id": llm_trace_id
        }

    except Exception as e:
        print(f"LLM 调用错误: {str(e)}")
        return {
            "prompt": "流行,女声,吉他伴奏,温柔,午后阳光",
            "lyrics": "[Intro]\n轻轻的\n微风吹过\n[Verse]\n心情如云朵\n飘荡在天空\n[Chorus]\n音乐带走烦恼\n旋律治愈心灵\n[Outro]\n慢慢地\n找回宁静",
            "llm_trace_id": f"Error: {str(e)}"
        }

def generate_music(prompt: str, lyrics: str, api_key: str) -> dict:
    """调用音乐生成 API，返回音频 URL 和 trace_id"""
    url = "https://api.minimaxi.com/v1/music_generation"

    print(f"=== Music API Request ===")
    print(f"URL: {url}")
    print(f"Model: music-2.0")
    print(f"Prompt: {prompt}")
    print(f"Lyrics length: {len(lyrics)} chars")
    print(f"========================")

    payload = {
        "model": "music-2.0",
        "prompt": prompt,
        "lyrics": lyrics,
        "audio_setting": {
            "sample_rate": 44100,
            "bitrate": 256000,
            "format": "mp3"
        },
        "output_format": "url"  # 关键：使用 URL 格式而不是 hex
    }

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    response = requests.post(url, headers=headers, json=payload)

    if response.status_code != 200:
        # 尝试获取 trace_id
        result = response.json() if response.content else {}
        music_trace_id = result.get('trace_id', 'N/A')
        raise HTTPException(
            status_code=response.status_code,
            detail=f"音乐生成失败。Trace-ID: {music_trace_id}"
        )

    result = response.json()

    # 从响应体中提取 trace_id
    music_trace_id = result.get('trace_id', 'N/A')
    print(f"Music API Trace-ID: {music_trace_id}")
    print(f"Response Status Code: {response.status_code}")

    if "data" not in result or "audio" not in result["data"]:
        raise HTTPException(
            status_code=400,
            detail=f"API返回数据格式错误。Trace-ID: {music_trace_id}"
        )

    # 获取音频 URL（不再是 hex 数据）
    audio_url = result["data"]["audio"]
    print(f"✅ Music API returned URL: {audio_url}")

    # 也获取 status
    status = result["data"].get("status")
    print(f"Music generation status: {status}")

    return {
        "url": audio_url,
        "trace_id": music_trace_id
    }

@router.get("/", response_class=HTMLResponse)
async def home(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@router.post("/generate_prompt")
async def generate_prompt(mood: str = Form(...), api_key: str = Form(...)):
    """第一步：只生成音乐提示词和歌词，供用户编辑"""
    try:
        # 验证 API Key
        if not api_key or api_key.strip() == "":
            raise HTTPException(status_code=400, detail="请提供有效的 API Key")

        # 使用 LLM 生成音乐提示词和歌词
        music_data = generate_music_prompt_with_llm(mood, api_key)
        prompt = music_data["prompt"]
        lyrics = music_data["lyrics"]
        llm_trace_id = music_data.get("llm_trace_id")

        return {
            "status": "success",
            "message": "提示词和歌词生成成功",
            "prompt": prompt,
            "lyrics": lyrics,
            "llm_trace_id": llm_trace_id
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error in generate_prompt endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/generate_music")
async def generate_music_endpoint(
    prompt: str = Form(...),
    lyrics: str = Form(...),
    api_key: str = Form(...)
):
    """第二步：使用提示词和歌词生成音乐"""
    try:
        # 验证 API Key
        if not api_key or api_key.strip() == "":
            raise HTTPException(status_code=400, detail="请提供有效的 API Key")

        # 验证 prompt 和 lyrics
        if not prompt or not lyrics:
            raise HTTPException(status_code=400, detail="请提供音乐风格和歌词")

        # 生成音乐
        music_result = generate_music(prompt, lyrics, api_key)
        audio_url = music_result["url"]
        music_trace_id = music_result["trace_id"]

        return {
            "status": "success",
            "message": "音乐生成成功",
            "audio_url": audio_url,
            "prompt": prompt,
            "lyrics": lyrics,
            "music_trace_id": music_trace_id
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error in generate_music endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/generate")
async def generate(mood: str = Form(...), api_key: str = Form(...)):
    """完整流程：生成提示词 + 生成音乐（兼容旧版）"""
    try:
        # 验证 API Key
        if not api_key or api_key.strip() == "":
            raise HTTPException(status_code=400, detail="请提供有效的 API Key")

        # 第一步：使用 LLM 生成音乐提示词和歌词
        music_data = generate_music_prompt_with_llm(mood, api_key)
        prompt = music_data["prompt"]
        lyrics = music_data["lyrics"]
        llm_trace_id = music_data.get("llm_trace_id")

        # 第二步：生成音乐（现在返回 URL 而不是本地文件路径）
        music_result = generate_music(prompt, lyrics, api_key)
        audio_url = music_result["url"]
        music_trace_id = music_result["trace_id"]

        return {
            "status": "success",
            "message": "音乐生成成功",
            "audio_url": audio_url,  # 改为 audio_url（直接 URL）
            "prompt": prompt,
            "lyrics": lyrics,
            "llm_trace_id": llm_trace_id,
            "music_trace_id": music_trace_id
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error in generate endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/download/{session_id}/{filename}")
async def download(session_id: str, filename: str):
    file_path = os.path.join(TEMP_DIR, session_id, filename)
    if os.path.exists(file_path):
        return FileResponse(
            file_path,
            media_type="audio/mpeg",
            headers={
                "Accept-Ranges": "bytes",
                "Content-Disposition": "inline"
            }
        )
    else:
        raise HTTPException(status_code=404, detail="文件不存在")

@router.get("/health")
async def health():
    return {"status": "healthy"}

# 将路由器包含到主应用
app.include_router(router)

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 5111))
    uvicorn.run(app, host="0.0.0.0", port=port)
