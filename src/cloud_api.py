import json
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

# Kế thừa engine LLM Local để chạy trên Cloud Server
from src.engines.llm_engine import LocalLLMEngine
from src.core.config import settings

app = FastAPI(title="EcoNutri Cloud API", version="1.0")

# Khởi tạo LLM Engine ngay khi API Server khởi động (Sẽ chiếm RAM của Cloud)
# Đảm bảo Cloud Server có thư mục weights/ và file model Qwen bên trong
llm_engine = LocalLLMEngine(
    model_path=settings.LLM_MODEL_PATH,
    n_ctx=settings.LLM_CONTEXT_WINDOW
)

# Khai báo cấu trúc dữ liệu mà app Streamlit (Local) sẽ gửi lên
class CompletionRequest(BaseModel):
    prompt: str
    max_tokens: int = 2048
    temperature: float = 0.2
    stream: bool = True

@app.post("/v1/completions")
async def create_completion(request: CompletionRequest):
    """
    Endpoint nhận Prompt từ Client, đưa vào mô hình Qwen, 
    và trả về từng chữ (Streaming) theo chuẩn SSE.
    """
    def stream_generator():
        # Gọi hàm model của llama_cpp
        response = llm_engine.model(
            prompt=request.prompt,
            stream=True,
            max_tokens=request.max_tokens,
            temperature=request.temperature,
            top_p=0.9,
            stop=["\n\nUser:", "\n\nQ:", "(Hồ sơ)", "(EcoNutri)", "<|im_end|>"],
        )
        
        # Đọc từng token từ model và đóng gói vào định dạng chuẩn của SSE
        for chunk in response:
            yield f"data: {json.dumps(chunk)}\n\n"
            
        # Phát tín hiệu báo cho Local biết câu trả lời đã tạo xong
        yield "data: [DONE]\n\n"

    # Trả về luồng dữ liệu liên tục (Stream)
    return StreamingResponse(stream_generator(), media_type="text/event-stream")