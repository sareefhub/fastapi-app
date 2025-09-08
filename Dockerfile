FROM python:3.11-slim

# ตั้ง working directory
WORKDIR /app

# คัดลอก requirements.txt และติดตั้ง dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# คัดลอกโค้ดทั้งหมดเข้า container
COPY . .

# เปิด port 8000
EXPOSE 8000

# รัน FastAPI ด้วย uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
