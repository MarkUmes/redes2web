import os
from flask import Flask, jsonify, render_template_string

app = Flask(__name__)
VERSION = "v2"


@app.get("/")
def root():
    return render_template_string("""<!doctype html>
<html lang="es"><meta charset="utf-8"><title>Flask en AWS</title>
<style>body{font:22px Arial;margin:60px;line-height:1.6}code{font-size:18px}</style>
<h1>pagina de prueba actualizada desde GitHub</h1>
<h2>CI/CD en la nube AWS</h2>
<p>Version: {{ version }}</p>
<p>Commit: <code>{{ revision }}</code></p>
<p>GitHub Actions &rarr; Docker Hub &rarr; Amazon EC2</p>
</html>""", version=VERSION, revision=os.getenv("BUILD_SHA", "local"))


@app.get("/health")
def health():
    return jsonify(status="ok", version=VERSION, revision=os.getenv("BUILD_SHA", "local"))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
