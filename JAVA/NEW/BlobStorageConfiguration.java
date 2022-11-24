package it.poste.codice.facommon.ms.configurations;


import java.util.Locale;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.core.annotation.Order;

import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.BlobServiceClientBuilder;
import com.azure.storage.blob.models.BlobListDetails;
import com.azure.storage.blob.models.ListBlobsOptions;
import com.azure.storage.common.StorageSharedKeyCredential;

import it.poste.codice.facommon.ms.batch.storage.AzureBlobStorageImpl;
import it.poste.codice.facommon.ms.batch.storage.FileStorage;
import it.poste.codice.facommon.ms.batch.storage.FilesystemStorageImpl;
import it.poste.common.logging.LoggerWrapper;

@Configuration
@Order(1)
public class BlobStorageConfiguration {

	private static LoggerWrapper log = new LoggerWrapper(BlobStorageConfiguration.class);

	@Value("${config.blob-storage.azure.account-name}")
	private String accountName;

	@Value("${config.blob-storage.azure.account-key}")
	private String accountKey;

	@Value("${config.blob-storage.azure.url}")
	private String endpoint;

	@Value("${config.blob-storage.azure.root-bucket}")
	private String azureBucket;

	@Value("${config.blob-storage.azure.stage-bucket}")
	private String azureStageBucket;

	@Value("${config.blob-storage.filesystem.root-filesystem}")
	private String rootFilesystem;



	@Bean
	@ConditionalOnProperty(name = "config.blob-storage.type",havingValue = "filesystem")
	public FileStorage getFilesystemStorage() {
		return new FilesystemStorageImpl(rootFilesystem);
	}

	@Bean
	@ConditionalOnProperty(name = "config.blob-storage.type",havingValue = "azure")
	public FileStorage getAzureStorage(BlobContainerClient blobContainerClient) {
		return new AzureBlobStorageImpl(blobContainerClient,azureBucket);
	}

	//	@Bean
	//	@ConditionalOnProperty(name = "config.blob-storage.azure.check-onstartup2")
	public BlobContainerClient getContainerClient() {
		final String AccountName="devstoreaccount1";
		final String AccountKey="Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==";
		final StorageSharedKeyCredential keyCredential = new StorageSharedKeyCredential(AccountName, AccountKey);
		//final BlobServiceClient blobServiceClient;
		try {

			final String endpoint1 = String.format(Locale.ROOT, "%s/%s",endpoint,accountName);
			final String endpoint2 = String.format(Locale.ROOT, "http://127.0.0.1:10000/%s",accountName);
			log.logMessage("accountName="+accountName+" azureBucket="+azureBucket+" endpoint="+endpoint+"/"+accountName);
			log.logMessage("endpoint2="+endpoint2);
			log.logMessage("endpoint2="+endpoint1);
			final String connectionString = "AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;DefaultEndpointsProtocol=http;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1;";
			//"DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;";
			/*
			 * Create a BlobServiceClient object that wraps the service endpoint, credential and a request pipeline.
			 */
			final BlobServiceClient storageClient = new BlobServiceClientBuilder().endpoint(endpoint1).credential(keyCredential).buildClient();
			//final BlobServiceClient storageClient = new BlobServiceClientBuilder().connectionString(connectionString).buildClient();
			//final BlobContainerClient blobContainerClient = storageClient.getBlobContainerClient("myjavacontainerbasic" + System.currentTimeMillis());

			//blobContainerClient.create();

			final BlobContainerClient blobContainerClient = storageClient.getBlobContainerClient(accountName+"/poste");
			//			final BlockBlobClient blobClient = blobContainerClient.getBlobClient("HelloWorld.txt").getBlockBlobClient();
			//
			//			final String data = "Hello world!";
			//			final InputStream dataStream = new ByteArrayInputStream(data.getBytes(StandardCharsets.UTF_8));
			//			blobClient.upload(dataStream, data.length());
			//			dataStream.close();
			//
			//			/*
			//			 * Download the blob's content to output stream.
			//			 */
			//			final int dataSize = (int) blobClient.getProperties().getBlobSize();
			//			final ByteArrayOutputStream outputStream = new ByteArrayOutputStream(dataSize);
			//			blobClient.download(outputStream);
			//			outputStream.close();
			//
			//			/*
			//			 * Create more blobs before listing.
			//			 */
			//			for (int i = 0; i < 3; i++) {
			//				final String sampleData = "Samples";
			//				final InputStream dataInBlobs = new ByteArrayInputStream(sampleData.getBytes(Charset.defaultCharset()));
			//				blobContainerClient.getBlobClient("myblobsforlisting" + System.currentTimeMillis()).getBlockBlobClient()
			//				.upload(dataInBlobs, sampleData.length());
			//				dataInBlobs.close();
			//			}
			//
			/*
			 * List the blob(s) in our container.
			 */

			final ListBlobsOptions options = new ListBlobsOptions().setDetails(new BlobListDetails().setRetrieveMetadata(true));
			blobContainerClient.listBlobs(options, java.time.Duration.ofSeconds(15))
			//			blobContainerClient.listBlobs()
			.forEach(blobItem -> System.out.println("Blob name: " + blobItem.getName() + ", Snapshot: " + blobItem.getSnapshot()));

			//blobServiceClient = new BlobServiceClientBuilder().endpoint(endpoint).credential(keyCredential).buildClient();
			//return storageClient.getBlobContainerClient(azureBucket);

			return blobContainerClient;
		} catch (final Exception e) {
			e.printStackTrace();
			return null;
		}

	}


	@Bean
	@Primary
	public BlobServiceClient rootBlobServiceClient() {
		final StorageSharedKeyCredential keyCredential = new StorageSharedKeyCredential(accountName, accountKey);
		log.logMessage("credential created");

		/*
		 * Create a BlobServiceClient object that wraps the service endpoint, credential and a request pipeline.
		 */
		final String storageEndpoint = String.format(Locale.ROOT, "%s",endpoint);
		log.logMessage("creating BlobServiceClient with azureBlobStorageEndpoint={}", storageEndpoint);

		try {
			final BlobServiceClient storageClient = new BlobServiceClientBuilder().endpoint(storageEndpoint).credential(keyCredential).buildClient();

			log.logMessage("BlobServiceClient created");
			return storageClient;
		} catch (final Exception e) {
			e.printStackTrace();
			throw e;
		}
	}

	@Bean
	@Primary
	public BlobContainerClient rootBlobContainerClient(BlobServiceClient rootBlobServiceClient) {
		log.logMessage("retrieve BlobContainerClient with stage bucket={}", azureBucket);
		return rootBlobServiceClient.getBlobContainerClient(azureBucket);

	}



}
