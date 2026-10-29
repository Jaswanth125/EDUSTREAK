from sentence_transformers import SentenceTransformer

class EmbeddingClient:
    """
    A client for generating text embeddings using a sentence-transformer model.
    
    This class loads a pre-trained model and provides a method to create
    embeddings for a list of text chunks.
    """
    def __init__(self, model_name='all-MiniLM-L6-v2'):
        """
        Initializes the EmbeddingClient and loads the sentence-transformer model.

        Args:
            model_name (str): The name of the model to use from sentence-transformers.
        """
        self.model = SentenceTransformer(model_name)
        print("Embedding model loaded.")

    def create_embeddings(self, chunks):
        """
        Generates embeddings for a list of text chunks.

        Args:
            chunks (list of str): A list of text strings to be embedded.

        Returns:
            list of list of float: A list of embeddings, where each embedding is a list of floats.
        """
        return self.model.encode(chunks, convert_to_tensor=False).tolist()

    def embed_query(self, query):
        """
        Generates an embedding for a single query string.

        Args:
            query (str): The query text to embed.

        Returns:
            list of float: The embedding for the query.
        """
        return self.model.encode(query, convert_to_tensor=False).tolist()
