FROM python:3.9.0-slim-buster
WORKDIR /usr/src/app
COPY ./repo/feature_store.yaml .
RUN pip install --no-cache-dir feast[aws]
#RUN feast init my_project
#WORKDIR /usr/src/app/my_project/feature_repo
#RUN feast apply
EXPOSE 8000
CMD ["feast", "ui", "-p", "8000"]