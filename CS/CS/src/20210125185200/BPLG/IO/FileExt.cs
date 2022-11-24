using System;
using System.Collections.Generic;
using System.Text;
using System.IO;

namespace BPLG.IO
{
    public class FileExt
    {
        //Sposta un file da un percorso ad un'altro, sovrascrivendolo se esisteva
        public static void MoveOverwrite(string sSourceFile, string sDestFile)
        {
            if (File.Exists(sDestFile))
                File.Delete(sDestFile);
            File.Move(sSourceFile, sDestFile);
        }
    }
}
