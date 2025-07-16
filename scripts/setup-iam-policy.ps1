# Script to create IAM policy for EC2 instance
# This should be run from AWS CLI or PowerShell with appropriate permissions

$PolicyDocument = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ],
            "Resource": "arn:aws:secretsmanager:*:*:secret:api-credentials*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:/aws/ec2/api-scheduler*"
        }
    ]
}
"@

Write-Host "IAM Policy Document for EC2 Instance Role:"
Write-Host $PolicyDocument
Write-Host ""
Write-Host "To apply this policy:"
Write-Host "1. Create an IAM role for your EC2 instance"
Write-Host "2. Attach this policy to the role"
Write-Host "3. Assign the role to your EC2 instance"
