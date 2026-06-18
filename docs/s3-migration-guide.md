# S3 Asset Migration Guide

This guide will help you migrate your existing assets from local storage (`public/system/`) to Amazon S3.

## Prerequisites

1. **AWS S3 bucket** - Create an S3 bucket for your assets
2. **AWS IAM credentials** - Create an IAM user with S3 permissions
3. **S3 configuration** - Add S3 settings to your application configuration

## Step 1: Configure S3 Credentials

Add the following environment variables to your `.env` file or system environment:

```env
# S3 Configuration
S3_BUCKET_NAME=your-bucket-name
S3_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
S3_CACHE_MAX_AGE=31536000
```

## Step 2: Update Application Configuration

Your application is already configured to use S3 when these credentials are present. The configuration is in `config/application.rb` and will automatically switch to S3 mode when the credentials are detected.

## Step 3: Test S3 Configuration

Before migrating, test that S3 is working by uploading a new image:

```bash
# Test that new uploads go to S3
rails console
> community = Community.first
> community.logo = File.open('path/to/test/image.jpg')
> community.save!
> puts community.logo.url
```

The URL should now point to your S3 bucket instead of `/system/...`.

## Step 4: Run the Migration

Execute the migration task to transfer all existing assets to S3:

```bash
# Migrate all assets to S3
rails assets:migrate_to_s3

# The migration will:
# 1. Find all models with attachments
# 2. Upload each file and all its styles to S3
# 3. Preserve the original file structure
# 4. Set appropriate cache headers and permissions
```

## Step 5: Verify the Migration

After migration, verify that files were uploaded correctly:

```bash
# Check that files exist on S3
rails assets:verify_s3_migration

# Manually test some URLs
rails console
> image = ListingImage.first
> puts image.image.url(:medium)
> puts image.image.url(:original)
```

## Step 6: Test Your Application

Before cleaning up local files, thoroughly test your application:

1. **Test image display** - Check that listing images, user avatars, and community logos display correctly
2. **Test file uploads** - Upload new images and verify they go to S3
3. **Test different image styles** - Verify thumbnails, medium, and original sizes work
4. **Test document downloads** - Check that PDFs and other documents are accessible

## Step 7: Clean Up Local Files (Optional)

⚠️ **Warning**: Only do this after thoroughly testing your application!

```bash
# Remove local files (PERMANENT - make sure S3 is working first!)
rails assets:cleanup_local_files
```

## Asset Types Being Migrated

The migration covers these asset types:

- **ListingImage** - All listing photos and their styles
- **Person** - User avatar images
- **Community** - Community logos, cover photos, favicons
- **PersonWhiteLabel** - White label logos
- **Document** - PDF documents and waivers
- **Listing** - PDF attachments
- **Mercury::Image** - CMS images

## File Structure on S3

Files will be organized on S3 as follows:

```
your-bucket/
├── images/
│   ├── listing_images/image/[id]/[style]/[filename]
│   ├── people/image/[id]/[style]/[filename]
│   ├── communities/logo/[id]/[style]/[filename]
│   └── ...
├── documents/
│   └── document/[id]/[style]/[filename]
└── pdfs/
    └── listings/pdf/[id]/[style]/[filename]
```

## Troubleshooting

### Migration Fails with "Access Denied"

Check your IAM permissions. The user needs:
- `s3:PutObject`
- `s3:PutObjectAcl`
- `s3:GetObject`

### Images Don't Display After Migration

1. Check that your S3 bucket allows public read access
2. Verify the bucket policy allows public access to objects
3. Check that the S3 region is correct in your configuration

### Some Files Are Missing

Run the verification task to identify missing files:

```bash
rails assets:verify_s3_migration
```

Re-run the migration if needed - it will skip files that already exist on S3.

## Sample S3 Bucket Policy

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::your-bucket-name/*"
        }
    ]
}
```

## Sample IAM Policy for Your User

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::your-bucket-name/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::your-bucket-name"
        }
    ]
}
```

## Performance Considerations

- The migration processes files in batches to avoid memory issues
- Large files (videos, high-res images) may take longer to upload
- Monitor your S3 costs - enable lifecycle policies if needed
- Consider using CloudFront CDN for better performance

## Rollback Strategy

If you need to rollback:

1. Remove S3 configuration from environment variables
2. The application will automatically fall back to local storage
3. New uploads will go to local storage again
4. Existing S3 URLs will break until files are restored locally

## Post-Migration Benefits

- **Reduced server storage** - Free up disk space on your server
- **Better performance** - Offload file serving to S3
- **Scalability** - S3 can handle unlimited file storage
- **Global CDN** - Use CloudFront for worldwide content delivery
- **Backup** - S3 provides built-in redundancy and backup options 