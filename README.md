# ECS Managed Orchestration

**A Fully Automated, Cloud-Native Logging & Observability System**\
*A cross-service microservice architecture powered by ECS, SQS, DynamoDB, and CloudWatch.*

------------------------------------------------------------------------

##  Overview

This project demonstrates an **end-to-end, serverless-inspired logging
pipeline** deployed entirely on AWS. It integrates **microservices**,
**messaging queues**, **data persistence**, and **observability** into a
**single orchestrated platform**.

Everything is **auto-deployed using Terraform and GitHub Actions**,
creating a truly **zero-touch CI/CD experience**.

------------------------------------------------------------------------

## Architecture

<img width="1246" height="798" alt="28871af9-0505-48e3-a5f2-b04d99ddded2" src="https://github.com/user-attachments/assets/9c9ca6b4-b029-427f-9b9c-5acbdab1cf6f" />

### Components

| Component  | Column2   | 
|-------------- | -------------- |
| **Service A & B**    | Simulated microservices generating structured logs |
| **Ingestor**    | Collects logs and pushes them to Amazon SQS |
| **Processor**    | Consumes from SQS, validates logs, and writes to DynamoDB |
| **CloudWatch**    | Provides centralized logging, metrics, and monitoring |
| **Terraform**   | Manages infrastructure declaratively |
| **GitHub Actions**    | Automates the CI/CD and ECS re-deployments |

### AWS Services Used

-   **Amazon ECS (Fargate)** -- Run containerized services serverlessly.
-   **Amazon SQS** -- Reliable decoupled message queue for log
    transport.
-   **Amazon DynamoDB** -- Serverless NoSQL storage for processed logs.
-   **Amazon CloudWatch** -- Unified observability and metric
    monitoring.
    <img width="1446" height="837" alt="2cf6a131-6a20-457a-94eb-f6887332e812" src="https://github.com/user-attachments/assets/1c3202ca-9fd3-47f8-8740-3553cc86d57e" />
-   **Amazon ECR** -- Private registry for Docker images.
-   **AWS IAM** -- Fine-grained access control and secure role
    delegation.

------------------------------------------------------------------------

## System Flow

<img width="1682" height="696" alt="d616e37e-f602-4b32-8fdb-4deaa7887ec2" src="https://github.com/user-attachments/assets/bf669ffb-6141-4032-8bee-dba2d8f8eb3e" />

1.  **Service A & B** generate log events (JSON-based).\
2.  **Ingestor ECS Service** receives and pushes them into **SQS
    Queue**.\
3.  **Processor ECS Service** polls messages, enriches them, and writes
    to **DynamoDB**.\
4.  **CloudWatch** captures metrics, service health, and ECS logs.\
5.  **CI/CD Pipeline** (GitHub Actions + Terraform) automatically
    updates infrastructure and containers.

------------------------------------------------------------------------

## Zero-Touch CI/CD

<img width="1273" height="939" alt="4ebe70ed-bc29-4575-9f2d-af60c2807c85" src="https://github.com/user-attachments/assets/1dcf1b0d-75dc-42dd-9446-328a6f9948bc" />

**Automation Highlights:** - On every `push` to `master`, the
pipeline: 1. Initializes Terraform and provisions ECR Repositories. 2.
Builds Docker images for all microservices. 3. Pushes the latest images
to ECR. 4. Applies infrastructure with Terraform (ECS, SQS, DynamoDB).
5. Forces ECS to pull and deploy new containers.

**Command Example:**

``` bash
aws ecs update-service   --cluster ecs-managed-orchestration   --service ecs-managed-orchestration-processor-svc   --force-new-deployment
```

------------------------------------------------------------------------

## Tech Stack

-   **Languages:** Python, Node.js\
-   **IaC:** Terraform\
-   **CI/CD:** GitHub Actions\
-   **Compute:** AWS ECS (Fargate)\
-   **Storage:** DynamoDB\
-   **Queue:** SQS\
-   **Monitoring:** CloudWatch\
-   **Registry:** ECR

------------------------------------------------------------------------

## Chaos Testing Ready

This architecture supports **fault injection testing**. You can: -
Simulate ECS service failure. - Delay or drop messages in SQS. - Observe
auto-recovery via CloudWatch metrics.

------------------------------------------------------------------------

## Key Learning Takeaways

-   Multi-container orchestration via ECS.
-   Infrastructure-as-Code with Terraform.
-   Event-driven design using SQS.
-   Cloud-native observability.
-   End-to-end CI/CD integration.

------------------------------------------------------------------------
