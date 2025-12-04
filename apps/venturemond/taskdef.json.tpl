{
  "family": "venturemond-web-prod",
  "executionRoleArn": "arn:aws:iam::535462128585:role/ecsTaskExecutionRole",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "venturemond-web-prod",
      "image": "REPLACE_ME",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ]
    }
  ]
}
