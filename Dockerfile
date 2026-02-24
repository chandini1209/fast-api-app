# Use AWS Lambda Python base image
FROM public.ecr.aws/lambda/python:3.11

# Copy requirements and install dependencies
COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip install --no-cache-dir -r ${LAMBDA_TASK_ROOT}/requirements.txt

# Copy application code
COPY main.py     ${LAMBDA_TASK_ROOT}/
COPY database.py ${LAMBDA_TASK_ROOT}/
COPY models.py   ${LAMBDA_TASK_ROOT}/
COPY schemas.py  ${LAMBDA_TASK_ROOT}/
COPY crud.py     ${LAMBDA_TASK_ROOT}/

# Lambda handler entry point
CMD ["main.handler"]