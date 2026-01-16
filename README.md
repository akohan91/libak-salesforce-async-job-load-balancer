# Async Job Load Balancer Framework

<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce" src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>
<a href="https://www.linkedin.com/in/akohan">
  <img
    alt="akohan91 | LinkedIn"
    src="https://content.linkedin.com/content/dam/me/business/en-us/amp/xbu/linkedin-revised-brand-guidelines/linkedin-logo/fg/brandg-linkedinlogo-hero-logo-dsk-v01.png.original.png"
    height="28px"
  >
</a>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## Overview

The **Async Job Load Balancer Framework** is an enterprise-grade, event-driven solution for managing and orchestrating asynchronous Apex jobs in Salesforce. Built for developers who need intelligent load balancing, automatic error handling, and comprehensive job lifecycle management for both Batch and Queueable Apex jobs.

This framework is designed for Salesforce developers who need to:
- Execute hundreds or thousands of async jobs efficiently
- Automatically manage Salesforce governor limits (flex queue, queueable depth)
- Track job execution with full audit trails
- Handle job failures gracefully with built-in error logging
- Scale asynchronous processing without manual intervention

---

## Features

✨ **Event-Driven Architecture** - Leverages Platform Events for decoupled, scalable job orchestration

🚀 **Automatic Load Balancing** - Intelligently queues jobs based on available flex queue slots and system capacity

🔄 **Job Lifecycle Management** - Track jobs from request to completion with automatic status updates

⚡ **Dual Job Support** - Seamlessly handles both Batchable and Queueable Apex jobs

🛡️ **Built-in Error Handling** - Automatic error capture, logging, and retry mechanisms

📊 **Full Audit Trail** - Complete visibility into job requests, execution times, and outcomes

🔧 **Extensible Design** - Easy to extend with custom event handlers and job executors

💡 **Declarative Job Creation** - Create job requests via UI, API, or code without complex setup

---

## Architecture

The framework uses a sophisticated event-driven architecture to decouple job creation from execution:

### Core Components

- **AsyncJobRequest__c** - Custom object storing job requests with status, payload, and metadata
- **AsyncJob__e** - Platform Event enabling real-time communication between components
- **Job Processors** - Execute batch and queueable jobs with automatic lifecycle management
- **Event Handlers** - Route and process job events (queue, status change, error)
- **Base Job Classes** - Abstract classes (`BatchableJob`, `QueueableJob`) with built-in event publishing

### How It Works

1. **Job Request Created** - Insert an `AsyncJobRequest__c` record
2. **Event Published** - Trigger publishes `QUEUE_JOB` event
3. **Event Routed** - `AsyncJobEventService` routes to appropriate handler
4. **Job Executed** - Processor instantiates your class and enqueues/executes it
5. **Status Updates** - Job publishes events as it progresses (Processing → Completed/Failed)
6. **Automatic Queueing** - Next job picks up when capacity becomes available

---

## Getting Started

### Installation

#### Option 1: Deploy to Salesforce Button

Click the "Deploy to Salesforce" button at the top of this README.

#### Option 2: SFDX CLI

```bash
# Clone the repository
git clone https://github.com/akohan91/libak-salesforce-async-job-load-balancer.git
cd libak-salesforce-async-job-load-balancer

# Deploy to your org
sfdx force:source:deploy -p force-app -u YourOrgAlias
```

#### Option 3: Manual Package Installation

1. Download the source code
2. Use Salesforce CLI or your preferred deployment tool
3. Deploy the `force-app` directory to your target org

### Quick Start

Create your first async job in 3 simple steps:

**Step 1:** Extend the base job class

```apex
public class MyBatchJob extends BatchableJob {
    protected override Database.QueryLocator doStart(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM Account]);
    }
    protected override void doExecute(Database.BatchableContext bc, List<SObject> scope) {
        // Your processing logic here
    }
    protected override void doFinish(Database.BatchableContext bc) {
        // Optional cleanup logic
    }
}
```

**Step 2:** Create a job request

```apex
insert new AsyncJobRequest__c(
    JobName__c = 'MyBatchJob',
    RecordTypeId = AsyncJobRequestConstants.recordType.BatchableId,
    BatchSize__c = 200
);
```

**Step 3:** Watch it run

The framework automatically queues, executes, and tracks your job. Monitor progress in the Async Job Requests tab.

### Documentation

📚 **[Developer Guide](Developer_Guide.md)** - Step-by-step tutorials and implementation examples

📖 **[API Reference](API_Reference.md)** - Complete technical documentation for all classes and methods

---

## Contributing

Contributions are welcome! Whether you're fixing bugs, improving documentation, or adding new features, your help makes this framework better for everyone.

### How to Contribute

1. **Fork the Repository**
   ```bash
   git clone https://github.com/akohan91/libak-salesforce-async-job-load-balancer.git
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
   Branch naming conventions:
   - `feature/` - New features
   - `bugfix/` - Bug fixes
   - `docs/` - Documentation updates

3. **Make Your Changes**
   - Write comprehensive tests
   - Update documentation if needed

4. **Commit Your Changes**
   ```bash
   git commit -m "Add: Brief description of your changes"
   ```

5. **Push and Create Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then open a Pull Request on GitHub with a clear description of your changes.

### Code Standards

- Follow SOLID principles and design patterns
- Bulkify all code for collections
- Use selector classes for SOQL queries
- Add tests with meaningful assertions
- Document public APIs with clear Apex docs

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Contact

**Andrei Kakhanouski**

For questions, suggestions, or collaboration opportunities, feel free to reach out!

---

> **Note:** This framework is actively maintained. For issues, feature requests, or contributions, please use the GitHub Issues and Pull Requests.
