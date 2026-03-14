"""
EcoNutri Core Package
Lớp vỏ bọc (Encapsulation) cho toàn bộ logic nghiệp vụ của dự án.
"""

__version__ = "1.0.0"
__author__ = "EcoNutri Team"

# Keep package init lightweight to avoid importing heavy optional dependencies
# (ultralytics, chromadb, etc.) during base package import.
__all__ = ["__version__", "__author__"]