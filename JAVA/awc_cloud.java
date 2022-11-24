import java.math.BigDecimal;

public class AWS_CLOUD {

	@Beta
	@BetaApi
	@InternalApi
	
	
	public void GOOGLE_04(org.joda.time.LocalDate Test)
	
	{
	}

	public com.google.common.io.OutputSupplier GOOGLE_04(org.joda.time.LocalDate Test)
	
	{
	}

	
	public void AWS()
	
	{
		AmazonDynamoDBClient dynamoDB = new AmazonDynamoDBClient(credentialsProvider.getCredentials());
		dynamoDB.setEndpoint("dynamodb.cn-north-1.amazonaws.com.cn");  //VIOLATION

		AmazonDynamoDBClient ddb = new AmazonDynamoDBClient(credentials);
		Region region = Region.getRegion(Regions.fromName(regionName));
		ddb.setRegion(region); //VIOLATION

		
	}
	
	@InternalExtensionOnly
	public void howToDeleteTable() throws InterruptedException {
        String TABLE_NAME = "myTableForMidLevelApi";
        Table table = dynamo.getTable(TABLE_NAME);
        // Wait for the table to become active or deleted
        TableDescription desc = table.waitForActiveOrDelete();
        if (desc == null) {
            System.out.println("Table " + table.getTableName() + " does not exist.");
        } else {
            table.delete();
            // No need to wait, but you could
            table.waitForDelete();
            System.out.println("Table " + table.getTableName() + " has been deleted");
        }
    }

	private String inefficientApiCallsNoncompliant(final String bucketName, final String key) throws IOException {
		AmazonS3 s3Client = AmazonS3ClientBuilder.standard().withRegion(Regions.US_EAST_1).build();
		// VIOLAZ: uses inefficient chain of API calls over an efficient single API call.
		S3Object s3object = s3Client.getObject(bucketName, key);
		try {
			return s3object.getObjectMetadata().getVersionId();
		} finally {
			s3object.close();
		}
	}

	@ExperimentalApi
	public void dynamoDBGetItemNoncompliant(Map<String, AttributeValue> key, String tableName) {
		AmazonDynamoDB dynamoDBClient = AmazonDynamoDBClientBuilder.standard().build();
		GetItemRequest request = new GetItemRequest()
				.withTableName(tableName)
				.withKey(key);
		try {
			GetItemResult result = dynamoDBClient.getItem(request);
			// VIOLAZ: result is not null-checked.
			System.out.println(result.getItem().get("key"));
		} catch (ResourceNotFoundException e) {
			log.error(e.getMessage());
		}
	}

	public void dynamoDBGetItemCompliant(Map<String, AttributeValue> key, String tableName) {
		AmazonDynamoDB dynamoDBClient = AmazonDynamoDBClientBuilder.standard().build();
		GetItemRequest request = new GetItemRequest()
				.withTableName(tableName)
				.withKey(key);
		try {
			GetItemResult result = dynamoDBClient.getItem(request);
			// OK: result is null-checked.
			if (result.getItem() != null) {
				System.out.println(result.getItem().get("key"));
			}
		} catch (ResourceNotFoundException e) {
			log.error(e.getMessage());
		}
	}

	public KinesisClientLibConfiguration configureKCLNoncompliant() {
		// VIOLAZ: doesn't set withCallProcessRecordsEvenForEmptyRecordList to true during Kinesis Client Library (KCL) initialization.
		KinesisClientLibConfiguration kclConfig = new KinesisClientLibConfiguration(applicationName,
				streamARN, ddbStreamCredentials, workerID)
				.withMaxRecords(maxRecords)
				.withIdleTimeBetweenReadsInMillis(idleTimeBetweenReadsInMillis)
				.withFailoverTimeMillis(leaseFailOverTimeInMillis)
				.withInitialPositionInStream(InitialPositionInStream.TRIM_HORIZON);
		return kclConfig;
	}

	public KinesisClientLibConfiguration configureKCLCompliant() {
		// OK: sets withCallProcessRecordsEvenForEmptyRecordList to true during Kinesis Client Library (KCL) initialization.
		KinesisClientLibConfiguration kclConfig = new KinesisClientLibConfiguration(applicationName,
				streamARN, ddbStreamCredentials, workerID)
				.withMaxRecords(maxRecords)
				.withCallProcessRecordsEvenForEmptyRecordList(true)
				.withIdleTimeBetweenReadsInMillis(idleTimeBetweenReadsInMillis)
				.withFailoverTimeMillis(leaseFailOverTimeInMillis)
				.withInitialPositionInStream(InitialPositionInStream.TRIM_HORIZON);
		return kclConfig;
		
		KinesisClientLibConfiguration kclConfig1;
		kclConfig1.withCallProcessRecordsEvenForEmptyRecordList (true);
	}

	public KinesisClientLibConfiguration configureKCLCompliant() {
		// VIOLAZ: sets withCallProcessRecordsEvenForEmptyRecordList to true during Kinesis Client Library (KCL) initialization.
		KinesisClientLibConfiguration kclConfig = new KinesisClientLibConfiguration(applicationName,
				streamARN, ddbStreamCredentials, workerID)
				.withMaxRecords(maxRecords)
				.withCallProcessRecordsEvenForEmptyRecordList(false) //VIOLAZ settato a false
				.withIdleTimeBetweenReadsInMillis(idleTimeBetweenReadsInMillis)
				.withFailoverTimeMillis(leaseFailOverTimeInMillis)
				.withInitialPositionInStream(InitialPositionInStream.TRIM_HORIZON);
		return kclConfig;
	}
	
	public Void handleRequest(ScheduledEvent scheduledEvent, Context context) {
			final long startTime = System.currentTimeMillis();
			doSomething(scheduledEvent, context);
			final long endTime = System.currentTimeMillis();
			final long timeElapsed = endTime - startTime;
			PutMetricDataRequest putMetricDataRequest = new PutMetricDataRequest();
			MetricDatum metricDatum = new MetricDatum().withMetricName("TIME_ELAPSED")
					.withUnit(StandardUnit.Milliseconds).withValue((double) timeElapsed);
			putMetricDataRequest.withNamespace("EXAMPLE_NAMESPACE").withMetricData(metricDatum);
			// VIOLAZ: uses CloudWatch to synchronically publish metrics from inside a Lambda.
			cloudwatch.putMetricData(putMetricDataRequest);
			return null;
		}
	
	public Void handleRequest(ScheduledEvent scheduledEvent, Context context) {
			LambdaLogger logger = context.getLogger();
			final long startTime = System.currentTimeMillis();
			doSomething(scheduledEvent, context);
			final long endTime = System.currentTimeMillis();
			final long timeElapsed = endTime - startTime;
			MetricDatum metricDatum = new MetricDatum().withMetricName("TIME_ELAPSED")
					.withUnit(StandardUnit.Milliseconds).withValue((double) timeElapsed);
			// OK: logs the metrics for further postprocessing outside the Lambda.
			logger.log("Metrics: " + metricDatum);
			return null;
		}
		
		public void describeImagesNoncompliant(AmazonEC2 client) {
			final String imageName = "sample_image_name";
			final Filter filter = new Filter("name").withValues(imageName);
			// VIOLAZ: images are filtered using name only.
			DescribeImagesResult result =
					client.describeImages(new DescribeImagesRequest().withFilters(filter));
		}

		public void describeImagesCompliant(AmazonEC2 client) {
			final String imageName = "sample_image_name";
			final String imageOwner = "sample_image_owner";
			final Filter nameFilter = new Filter("name").withValues(imageName);
			final Filter ownerFilter = new Filter("owner-alias").withValues(imageOwner);
			// OK: images are filtered using name and owner.
			DescribeImagesResult result =
					client.describeImages(new DescribeImagesRequest().withFilters(Arrays.asList(nameFilter, ownerFilter)));
		}

		public void s3MultiPartUploadNoncompliant() {
			AmazonS3 s3Client = AmazonS3ClientBuilder.standard()
					.withRegion(Regions.US_EAST_1)
					.build();
			// VIOLAZ: uses an API that we don't recommend, and a better alternative exists.
			s3Client.initiateMultipartUpload(new InitiateMultipartUploadRequest(bucketName,key));
		}

	public void getUserMetaDataNoncompliant(ObjectMetadata objectMetadata) {
		// VIOLAZ: the metadata key contains an uppercase letter.
		objectMetadata.getUserMetaDataOf("Key");
	}

}

public class AwsServiceClientInitializationNoncompliant implements RequestHandler<String, Void> {

    private DataPipeline dataPipeline;

    public void AwsServiceClientInitializationNoncompliant() {
        // VIOLAZ: AWS region provider not specified.
        dataPipeline = DataPipelineAsyncClientBuilder.defaultClient();
    }

    @Override
    public Void handleRequest(String requestEvent, Context context) {
        // Handle the request here.
        return null;
    }
}

public class DynamodbTransactionLibraryNoncompliant {
    public void createTransactionNoncompliant() throws Exception {
        // VIOLAZ: uses AWS Lab Transactions Library over DynamoDB native transactional APIs.
        TransactionManager.verifyOrCreateTransactionTable("client", "Transactions", 1, 1, null);
    }
	
	public InvokeResult invokeLambdaNoncompliant() {
		AWSLambda awsLambdaClient = AWSLambdaClientBuilder.standard().build();
		final InvokeRequest request = new InvokeRequest();
		// VIOLAZ: manual retry if a service exception is thrown.
		for(int i=0; i <= 5; i++) {
			try {
				return awsLambdaClient.invoke(request);
			} catch (AmazonServiceException e) {
				log.error("Exception: " + e);
			}
		}
		return null;
	}

	public void changeSqsMessageVisibilityNoncompliant(AmazonSQS amazonSqsClient, ChangeMessageVisibilityRequest request) {
		// VIOLAZ: MessageNotInFlight exception is not checked when changing message visibility.
		amazonSqsClient.changeMessageVisibility(request);
	}

	public void changeSqsMessageVisibilityCompliant(AmazonSQS amazonSqsClient, ChangeMessageVisibilityRequest request) {
		// OK: MessageNotInFlight exception is checked when changing message visibility.
		try {
			amazonSqsClient.changeMessageVisibility(request);
		} catch (MessageNotInflightException ex1) {
			log.info(format("Message with receipt handle %s already visible. Too late to abandon", request.getReceiptHandle()));
		} catch (Exception ex2) {
			log.error(format("Caught unknown exception %s", request.getReceiptHandle()), ex);
		}
		
		try {
		  int[] myNumbers = {1, 2, 3};
		  System.out.println(myNumbers[10]);
			try {
				
				System.out.println(myNumbers[10]);
				
				try {
					System.out.println(myNumbers[10]);
				}
				
				catch (Exception ex3) {}
			}
			catch (Exception ex4) {}
			catch (Exception ex5) {}
		} 
		catch (Exception ex6) {
			System.out.println("Something went wrong.");
		}
		finally {
			System.out.println("The 'try catch' is finished.");
		}
		
	}

	public void transferManagerNoncompliant(PutObjectRequest putRequest) {
		// VIOLAZ: transferManager is not shutdown.
		TransferManager transferManager = TransferManagerBuilder.defaultTransferManager();
		try {
			final Upload upload = transferManager.upload(putRequest);
			upload.waitForCompletion();
		}
		catch (InterruptedException e) {
			Thread.currentThread().interrupt();
		}
	}

	public void transferManagerCompliant(PutObjectRequest putRequest) {
		TransferManager transferManager = TransferManagerBuilder.defaultTransferManager();
		try {
			final Upload upload = transferManager.upload(putRequest);
			upload.waitForCompletion();
		}
		catch (InterruptedException e) {
			Thread.currentThread().interrupt();
		} finally
		{
			// OK: transferManager is shutdown.
			transferManager.shutdownNow();
		}
	}
	
	public void createStepConfigNoncompliant() {
		// VIOLAZ: ActionOnFailure.TERMINATE_JOB_FLOW is outdated.
		new StepConfig().withName("sampleStepName").withActionOnFailure(ActionOnFailure.TERMINATE_JOB_FLOW);
	}

	public void s3PutObjectNoncompliant(String bucket, String key, InputStream content,
										ObjectMetadata metadata, AmazonS3 s3Client, String owner) {
		log.info("Putting content into bucket {} and key {}", bucket, key);
		// VIOLAZ: readLimit not set.
		PutObjectRequest putObjectRequest = new PutObjectRequest(bucket, key, content, metadata);
		putObjectRequest.setExpectedBucketOwner(owner);
		s3Client.putObject(putObjectRequest);
	}

}

public class AwsDynamodbMapperBatchOutputIgnoredNoncompliant extends DynamoBatchWriteOutputNoncompliant {
		//aws-dynamodb-mapper-batch-output-ignored@v1.0
		AmazonDynamoDB client = AmazonDynamoDBClientBuilder.standard().withRegion(Regions.US_EAST_1).build();
		DynamoDBMapper myDynamoDBMapper = new DynamoDBMapper(client);
		@Override
		public void mapperNoncompliant(DynamoDBMapperCollection<String> batch) {
			// VIOLAZ: does not have checks to handle errors returned by batch operation.
			List<FailedBatch> failures = myDynamoDBMapper.batchSave(batch);
			System.out.println("Completed Dynamo Batch Write Operation");
			batch.clear();
		}
		
		public void flushNoncompliant(final SqsClient amazonSqs,
                              final String sqsEndPoint,
                              final List<SendMessageBatchRequestEntry> batch)
        throws CloneNotSupportedException {
			if (batch.isEmpty()) {
				return;
			}
			SendMessageBatchResult sendResult =
					amazonSqs.sendMessageBatch(sqsEndPoint, batch);
			// VIOLAZ: no checks to handle errors returned by batch operations.
			batch.clear();
		}

	public void flushCompliant(final SqsClient amazonSqs,
							   final String sqsEndPoint,
							   final List<SendMessageBatchRequestEntry> batch)
			throws SQSUpdateException, CloneNotSupportedException {
		if (batch.isEmpty() || sqsEndPoint == null) {
			return;
		}
		SendMessageBatchResult sendResult =
				amazonSqs.sendMessageBatch(sqsEndPoint, batch);
		if (sendResult == null) {
			return;
		} else {
			final List<BatchResultErrorEntry> failed = sendResult.getFailed();
			// OK: has checks to handle errors returned by batch operations.
			if (!failed.isEmpty()) {
				final String failedMessage = failed.stream()
						.map(batchResultErrorEntry -> String.format("messageId:%s failedReason:%s",
								batchResultErrorEntry.getId(), batchResultErrorEntry.getMessage()))
						.collect(Collectors.joining(","));
				throw new SQSUpdateException("Error occurred while sending messages to SQS::" + failedMessage);
			}
		}
	}

	}

public class AwsDynamodbMapperBatchOutputIgnoredCompliant extends DynamoBatchWriteOutputCompliant {
		AmazonDynamoDB client = AmazonDynamoDBClientBuilder.standard().withRegion(Regions.US_EAST_1).build();
		DynamoDBMapper myDynamoDBMapper = new DynamoDBMapper(client);
		@Override
		public List<String> mapperCompliant(DynamoDBMapperCollection<String> batch) {
			// OK: has checks to handle errors returned by batch operation.
			List<FailedBatch> failures = myDynamoDBMapper.batchSave(batch);
			return failures.stream()
					.map(FailedBatch -> String.format("messageId:%s failedReason:%s",
							FailedBatch.getException(),
							FailedBatch.getUnprocessedItems())).collect(Collectors.toList());
		}
	}

