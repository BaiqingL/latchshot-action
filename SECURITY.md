# Security

Never commit a Latchshot API key to a repository, workflow, issue, artifact, or log. Store it as a GitHub Actions secret named `LATCHSHOT_API_KEY` and pass it through the `api_key` input.

The action sends the key only in the HTTPS `Authorization` header. It does not print the key or place it in the requested URL.

For a vulnerability in this repository, use GitHub's private vulnerability reporting feature. For compromised credentials, revoke the key through the Latchshot owner and replace the repository secret.

Latchshot accepts public HTTP/HTTPS targets only. Do not use it to capture content you do not have the right to capture.
