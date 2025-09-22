# CodeQL Security Scanning Setup

This repository includes a pre-configured CodeQL workflow for security scanning. To enable code scanning alerts and results in the repository, follow these steps:

## Enabling Code Scanning in Repository Settings

### 1. Navigate to Repository Settings
1. Go to your repository on GitHub
2. Click on the **Settings** tab
3. In the left sidebar, click on **Code security and analysis**

### 2. Enable Code Scanning
1. Find the **Code scanning** section
2. Click **Set up** next to "Code scanning alerts"
3. Choose **GitHub Actions** as the scanning method
4. Select **Use existing workflow** since we already have `.github/workflows/codeql.yml`

### 3. Configure Scanning Options
The CodeQL workflow is already configured with:
- **Languages**: C# (.NET)
- **Triggers**: 
  - Push to `main` and `develop` branches
  - Pull requests to `main` and `develop` branches  
  - Weekly scheduled scan (Mondays at 6 AM UTC)
- **Query Suites**: Security and quality queries
- **Permissions**: Proper read/write permissions for security events

### 4. Verify Setup
After enabling code scanning:
1. Check the **Security** tab in your repository
2. You should see a **Code scanning alerts** section
3. The workflow will run automatically on the next push or PR

## Workflow Details

The CodeQL workflow (`.github/workflows/codeql.yml`) includes:

- **Security-focused scanning** with extended security queries
- **Quality analysis** for code maintainability
- **Automatic dependency caching** for faster builds
- **Integration with .NET 8** build process
- **Scheduled weekly scans** for continuous monitoring

## Viewing Results

Once code scanning is enabled and workflows have run:

1. **Security Tab**: View all security alerts and their status
2. **Pull Request Checks**: See scanning results directly in PRs
3. **Code Annotations**: Get line-by-line security feedback
4. **Trend Analysis**: Monitor security posture over time

## Troubleshooting

If code scanning doesn't appear to be working:

1. Check that the repository has **Actions** enabled in Settings > Actions
2. Verify the workflow has the necessary **permissions** (already configured)
3. Ensure the repository has **security features** enabled for private repos
4. Check the **Actions** tab for any workflow failures

## Additional Security Features

Consider enabling these additional security features:

- **Dependabot alerts**: Automatic dependency vulnerability scanning
- **Secret scanning**: Detection of accidentally committed secrets  
- **Dependency review**: PR-based dependency security analysis
- **Security advisories**: Private disclosure of security issues

---

For more information, see the [GitHub Code Scanning Documentation](https://docs.github.com/en/code-security/code-scanning).