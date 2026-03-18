import os
from huggingface_hub import hf_hub_download

def setup_weights():
    # 1. Xác định đường dẫn gốc của dự án (Project Root)
    # Vì script nằm trong thư mục 'scripts/', ta lấy thư mục cha của nó
    current_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(current_dir)
    weights_dir = os.path.join(project_root, "weights")

    # 2. Tạo thư mục weights ở cấp gốc nếu chưa có
    if not os.path.exists(weights_dir):
        os.makedirs(weights_dir)
        print(f"📁 Đã tạo thư mục: {weights_dir}")

    # 3. Danh sách model cần tải
    models = [
        {
            "repo_id": "nvfus12/Vietnam-food-object-detection",
            "filename": "yolo26n_best.pt"
        },
        {
            "repo_id": "Qwen/Qwen2.5-3B-Instruct-GGUF",
            "filename": "qwen2.5-3b-instruct-q4_k_m.gguf"
        },
        {
            "repo_id": "nvfus12/eco-nutri-questions-filter",  
            "filename": "safety_filter_model.joblib"
        },
        {
            "repo_id": "Qwen/Qwen2.5-0.5B-Instruct-GGUF",  
            "filename": "qwen2.5-0.5b-instruct-q4_k_m.gguf"
        }
    ]

    print("--- 🚀 Đang tải Model về thư mục /weights ---")

    for model in models:
        print(f"\n[Đang tải] {model['filename']}...")
        try:
            # Tham số local_dir chỉ định chính xác nơi lưu file
            hf_hub_download(
                repo_id=model["repo_id"],
                filename=model["filename"],
                local_dir=weights_dir,
                local_dir_use_symlinks=False  # Ép tải file vật lý thay vì tạo link ảo
            )
            print(f"✅ Thành công: {model['filename']}")
        except Exception as e:
            print(f"❌ Lỗi: {e}")

if __name__ == "__main__":
    setup_weights()