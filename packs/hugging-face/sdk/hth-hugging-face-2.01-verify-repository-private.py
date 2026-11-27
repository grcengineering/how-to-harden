# HTH Pack Contract: v1
#   control: hugging-face-2.1
#   guide: https://howtoharden.com/guides/hugging-face/#21-make-sensitive-repositories-private
#   profile: L1
#   mode: read-only
#   requires: hf CLI, huggingface_hub or curl with Python 3, scoped Hub credentials
# HTH hugging-face 2.1: Make sensitive repositories private
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/hugging-face/
# Reference: https://huggingface.co/docs/huggingface_hub/en/package_reference/hf_api
# HTH Guide Excerpt: begin verify-repository-private
import os
from huggingface_hub import HfApi

repo_id = os.environ["HF_REPO_ID"]
repo_type = os.environ["HF_REPO_TYPE"]
if repo_type not in {"model", "dataset", "space"} or len(repo_id.split("/")) != 2:
    raise SystemExit("Specify the exact organization repository and type.")
result = HfApi(endpoint="https://huggingface.co").repo_info(repo_id, repo_type=repo_type)
if getattr(result, "private", None) is not True:
    raise SystemExit("Repository privacy is not verified.")
print("Repository is private.")
# HTH Guide Excerpt: end verify-repository-private
