FROM python:3.10-slim
WORKDIR /app
COPY main.py .
RUN pip install Flask
EXPOSE 5000
CMD [ "python","main.py" ]
