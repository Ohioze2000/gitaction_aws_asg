# GitOps-Native AWS Infrastructure

## 🏗️ Architecture Diagram

```mermaid

%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#232f3e', 'edgeLabelBackground':'#ffffff', 'tertiaryColor': '#fff'}}}%%

graph TD
    %% --- Define Nodes/Icons ---
    subgraph Users_Layer [Access Layer]
        User[("fa:fa-user End Users")]
        SlackDevs[("fa:fa-slack Maintainers/Devs")]
    end

    subgraph GitHub [GitOps Workflow: GitHub]
        Repo[("fa:fa-github Git Repository")]
        ActionRunner["fa:fa-cogs GitHub Action Runner"]
    end

    subgraph AWS_Cloud [AWS Cloud]
        TF_Cloud[("fa:fa-cloud Terraform Cloud<br/>(State Lock/Auth)")]

        subgraph VPC [Custom VPC: us-east-1]
            IGW["fa:fa-door-open Internet Gateway"]

            %% Internal Services
            ACM["fa:fa-certificate AWS ACM<br/>(SSL/TLS)"]
            R53[("fa:fa-search Route 53<br/>(DNS A Record Alias)")]
            Secrets[("fa:fa-key AWS Secrets Manager")]

            subgraph Public_Subnets ["Public Subnets (AZ-A, AZ-B)"]
                ALB["fa:fa-exchange-alt Application Load Balancer (ALB)"]
                NAT_GW["fa:fa-network-wired NAT Gateway"]
            end

            subgraph Private_Subnets ["Private Subnets (AZ-A, AZ-B)"]
                ASG["fa:fa-tasks Auto Scaling Group (ASG)"]
                TargetGroup[("fa:fa-list Target Group")]
                LT["fa:fa-file-code Launch Template"]

                %% Instance Cluster
                subgraph App_Nodes [Webserver Nodes]
                    EC2_A["fa:fa-server EC2 Node A<br/>(App + UserData)"]
                    EC2_B["fa:fa-server EC2 Node B<br/>(App + UserData)"]
                end
            end

            %% Observability Subgraph
            subgraph Monitoring_Layer [Observability & Alerting]
                CW_Alarm["fa:fa-bell CloudWatch Alarm"]
                SNS_Topic[("fa:fa-comment-alt SNS Topic <br> Slack Alerts")]
            end
        end
    end

    %% --- Connect the Nodes (Define Flow) ---

    %% 1. GitOps / IaC Workflow
    Repo -- "1. Git Push" --> ActionRunner
    ActionRunner -- "2. Authenticate (Secret Keys)" --> TF_Cloud
    TF_Cloud -- "3. Deploy HCL (Modules)" --> VPC

    %% 2. User Traffic Flow (Data Path)
    User -- "4. Visit: app.yourdomain.com" --> R53
    R53 -- "5. Resolve Alias" --> ALB
    ALB -.-> ACM
    ALB -- "6. Forward Traffic (Port 80)<br/>(SG Chaining)" --> TargetGroup
    TargetGroup -- "7. Direct to Healthiest" --> App_Nodes

    %% 3. Instance Internet Path
    App_Nodes -- "8. Apt Install (user_data)" --> NAT_GW
    NAT_GW --> IGW

    %% 4. Management Loop (ASG)
    ASG -- "9. Provisions via" --> LT
    LT -- "10. Spawns/Replaces" --> App_Nodes

    %% 5. Observability Loop (The 'Speech' Path)
    EC2_A & EC2_B -- "11. Metrics (CPU, 5xx)" --> CW_Alarm
    CW_Alarm -- "12. Breach Detected (ALARM)" --> SNS_Topic
    SNS_Topic -- "13. Authenticate (Webhook URL)" -.-> Secrets
    SNS_Topic -- "14. Post actionable alerts to Slack" --> Slack

    %% --- Stylize Nodes ---
    %% Colors: Blue (Entry), Green (Success Path), Red (Monitor), Dark (AWS Core)
    classDef gitHub fill:#fcfcfc,stroke:#333,stroke-width:1px;
    classDef awsCore fill:#232f3e,stroke:#fff,stroke-width:1px,color:#fff;
    classDef subnet fill:#f7f7f7,stroke:#666,stroke-width:1px,stroke-dasharray: 5 5;
    classDef observability fill:#fff0f0,stroke:#ec1c24,stroke-width:1px,color:#ec1c24;
    classDef internet fill:#f0faff,stroke:#007bff,stroke-width:1px;
    classDef secrets fill:#fffbe6,stroke:#d48806,stroke-width:1px;

    %% Apply Classes
    class Repo,ActionRunner gitHub;
    class VPC,ALB,ASG,LT,EC2_A,EC2_B awsCore;
    class Public_Subnets,Private_Subnets subnet;
    class CW_Alarm,SNS_Topic observability;
    class R53,ACM,IGW internet;
    class Secrets secrets;
```

## 📌 Project Overview
This project is a production-grade, two-tier AWS architecture managed through a **CI/CD pipeline**. It demonstrates a modern developer workflow where infrastructure is treated as code, and all deployments are handled automatically via **GitHub Actions**.

## 🔄 The CI/CD Workflow
1. **Develop:** Infrastructure is defined using Terraform (HCL) on a local machine.
2. **Push:** Code is pushed to the GitHub repository.
3. **Automate:** GitHub Actions triggers a workflow that authenticates to AWS using Secret Access Keys.
4. **Deploy:** Terraform Cloud executes the `plan` and `apply`, provisioning the updated resources in AWS.

## 🚀 Technical Stack
- **IaC:** Terraform & Terraform Cloud
- **CI/CD:** GitHub Actions (Self-hosted/GitHub-hosted runners)
- **Cloud:** AWS (VPC, EC2, ASG, ALB, CloudWatch, Secrets Manager)
- **Security:** Encrypted GitHub Secrets and Terraform Sensitive Variables

## 🏗️ Architecture Overview
- **Networking:** Custom VPC with Public and Private subnets.
- **Compute:** Auto Scaling Group (ASG) ensuring high availability and self-healing.
- **Load Balancing:** Application Load Balancer (ALB) with Security Group Chaining.
- **Observability:** CloudWatch Alarms monitoring health, integrated with **Slack** for real-time notifications.

## 🛠️ Infrastructure Modules
* `/modules/network`: VPC, Subnets, IGW, and NAT Gateways.
* `/modules/iam`: Specialized ECS Task Execution and Task Roles.
* `/modules/alb`: Load Balancer, Listeners, and Target Groups.
* `/modules/webserver`: ASG, Launch Templates, and Instance SGs.
* `/modules/dns`: Route 53 Records.
* `/modules/ssl`: SSL Validation.
* `/modules/monitoring`: SNS Topic, CloudWatch Metric Alarm, SNS Topic Subscription, and CloudWatch Dashboard.

## 🚦 Prerequisites & secrets
Before deploying, ensure you have:
1. An **AWS Account** with IAM credentials.
2. An **HCP Terraform** account and workspace.
3. **GitHub Secrets** configured:
   - `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
   - `TF_API_TOKEN`
   - `SLACK_WEBHOOK_URL`

## ⚙️ How to Deploy
1. **Clone the Repo:**
   ```bash
   git clone https://github.com/Ohioze2000/gitaction_aws_asg.git

2. Update Variables:
Modify terraform.tfvars or your HCP Terraform workspace variables to match your domain and environment settings.

3. Push to Main:

Bash
git add .
git commit -m "feat: initial deployment"
git push origin main

4. Monitor Slack:
The pipeline will notify your Slack channel once the application is live and provide the ALB DNS URL.

🧹 Cleanup
To tear down the infrastructure and avoid costs:

Go to GitHub Actions -> Infrastructure Cleanup.

Run the workflow manually by cliicking Run workflow.

🧠 Lessons Learned
The Project provided deep insights into the nuances of cloud automation and the realities of managing infrastructure-as-code in a CI/CD environment.

1. Solving the "502 Bad Gateway" Mystery
Perhaps the most significant technical hurdle was resolving a 502 error when accessing the site via a custom domain.
I learned that infrastructure is more than just code; it's a handshake. The issue required auditing the Security Group Chaining and verifying the Route 53 Alias record. I discovered that even if the ALB DNS works, a misconfigured host-header or a stale DNS record can break the entire user experience.

2. Remote State is Non-Negotiable
Transitioning from local state files to HCP Terraform (Terraform Cloud) was a turning point. It taught me the importance of state locking and centralized management in a collaborative environment, preventing "state corruption" that often happens during concurrent runs.