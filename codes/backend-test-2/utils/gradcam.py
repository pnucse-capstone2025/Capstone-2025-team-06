# app/utils/gradcam.py
import torch
import torch.nn.functional as F
import numpy as np

def _is_scripted(model):
    return "ScriptModule" in type(model).__name__

def _find_last_conv(module):
    last = None
    for _, m in module.named_modules():
        if isinstance(m, torch.nn.Conv2d):
            last = m
    return last

def _score_and_probs(out, class_idx=None):
    # Supports logits (N,C) or single logit (N,1)
    if out.ndim == 2 and out.shape[1] >= 2:
        probs = F.softmax(out, dim=1)[0]  # (C,)
        idx = int(torch.argmax(probs).item()) if class_idx is None else int(class_idx)
        score = out[:, idx]
        return float(probs[idx].item()), score, probs.detach().cpu().numpy()
    else:
        # Binary sigmoid case
        p1 = float(torch.sigmoid(out)[0].item())
        idx = 1 if (class_idx is None) else int(class_idx)
        score = out if idx == 1 else -out
        return p1, score, np.array([1.0 - p1, p1])

def _gradcam_core(model, tensor, layer, class_idx=None, device="cpu"):
    fmap, grads = {}, {}
    def fwd_hook(_, __, output): fmap["x"] = output
    def bwd_hook(_, grad_in, grad_out): grads["x"] = grad_out[0]
    h1 = layer.register_forward_hook(fwd_hook)
    h2 = layer.register_backward_hook(bwd_hook)

    tensor = tensor.to(device)
    out = model(tensor)
    prob, score, probs_vec = _score_and_probs(out, class_idx)

    model.zero_grad()
    score.backward(retain_graph=True)

    w = grads["x"].mean(dim=(2, 3), keepdim=True)
    cam = (w * fmap["x"]).sum(dim=1, keepdim=True)
    cam = F.relu(cam)
    cam = F.interpolate(cam, size=tensor.shape[2:], mode="bilinear", align_corners=False)
    cam = cam.squeeze().detach().cpu().numpy()
    cam = (cam - cam.min()) / (cam.max() - cam.min() + 1e-8)

    h1.remove(); h2.remove()
    return prob, cam, probs_vec

def _saliency_fallback(model, tensor, class_idx=None, device="cpu"):
    tensor = tensor.to(device).clone().detach().requires_grad_(True)
    out = model(tensor)
    prob, score, probs_vec = _score_and_probs(out, class_idx)
    model.zero_grad(); score.backward(retain_graph=False)
    grad = tensor.grad.detach().cpu().numpy()[0]  # (C,H,W)
    sal = np.abs(grad).max(axis=0)
    sal = (sal - sal.min()) / (sal.max() - sal.min() + 1e-8)
    return prob, sal, probs_vec

def explain_image(model, tensor, device="cpu", preferred_layer_name=None, class_idx=None):
    # TorchScript? go saliency directly
    if _is_scripted(model):
        return _saliency_fallback(model, tensor, class_idx, device)
    # Preferred
    if preferred_layer_name is not None:
        layer = dict(model.named_modules()).get(preferred_layer_name)
        if layer is not None:
            try:
                return _gradcam_core(model, tensor, layer, class_idx, device)
            except Exception:
                pass
    # Auto last conv
    layer = _find_last_conv(model)
    if layer is not None:
        try:
            return _gradcam_core(model, tensor, layer, class_idx, device)
        except Exception:
            pass
    # Fallback
    return _saliency_fallback(model, tensor, class_idx, device)
