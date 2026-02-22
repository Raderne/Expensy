using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Infrastructure.Services
{
    public class NullStorageService : IStorage
    {
        public Task<string> CreateFolderAsync(string absolutePath, string folderRelativePath)
        {
            throw new NotImplementedException();
        }

        public Task<bool> DeleteFileAsync(string fileAbsolutePath)
        {
            throw new NotImplementedException();
        }

        public Task<bool> DeleteFolderAsync(string absolutePath, string folderRelativePath)
        {
            throw new NotImplementedException();
        }

        public void Dispose()
        {

        }

        public Task<byte[]?> GetFileAsBytesAsync(string fileAbsolutePath)
        {
            throw new NotImplementedException();
        }

        public Task<Stream?> GetFileAsync(string fileAbsolutePath)
        {
            throw new NotImplementedException();
        }

        public Task<List<string>> GetFilesAsync(string absolutePath, string folderRelativePath)
        {
            throw new NotImplementedException();
        }

        public Task<List<string>> GetFoldersAsync(string absolutePath, string folderRelativePath)
        {
            throw new NotImplementedException();
        }

        public Task<string> SaveFileAsync(byte[] data, string absolutePath, string fileName)
        {
            throw new NotImplementedException();
        }

        public Task<string> SaveFileAsync(Stream stream, string absolutePath, string fileName)
        {
            throw new NotImplementedException();
        }
    }
}
