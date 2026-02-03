using System;
using System.Collections;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace PackersTools
{
    internal class Program
    {
        // Application GUID: {f0fedeaf-cfbf-45cb-93ad-27f255783d13}

        static void Main(string[] args)
        {
            if (args.Length == 0)
            {
                Console.WriteLine("Please provide a command and path");
                Console.WriteLine("Press any key to close...");
                Console.ReadKey();
                return;
            }
            string command = args[0];
            string path = args[1];

            if (command == null || path == null)
            {
                Console.WriteLine("Command and path cannot be null.");
                Console.WriteLine("Press any key to close...");
                Console.ReadKey();
                return;
            }

            switch (command.ToLower())
            {
                case "build":
                    BuildDirectory(path);
                    break;
                case "new":
                    NewPackage(path);
                    break;
                case "template":
                    OpenTemplateDirectory();
                    break;
                default:
                    Console.WriteLine($"Unknown command: {command}");
                    Console.WriteLine("Press any key to close...");
                    Console.ReadKey();
                    break;
            }
        }

        static string DetectPackageType(string path)
        {
            string[] files = Directory.GetFiles(path);
            foreach (var file in files)
            {
                if (file.Contains("Deploy-Application.exe"))
                {
                    Console.WriteLine("Detected PSADT v3 package!");
                    return "Deploy-Application.exe";
                }
                else if (file.Contains("Invoke-AppDeployToolkit.exe"))
                {
                    Console.WriteLine("Detected PSADT v4 package!");
                    return "Invoke-AppDeployToolkit.exe";
                }
            }
            Console.WriteLine("No known package type detected!");
            do
            {
                Console.Write("Enter setup file name: ");
                string? input = Console.ReadLine();
                if (!string.IsNullOrEmpty(input) && File.Exists(Path.Combine(path, input)))
                {
                    return input;
                }
                else
                {
                    Console.WriteLine("File does not exist in the specified path. Please try again.\n");
                }
            } while (true);
        }

        static void BuildDirectory(string path)
        {
            Console.WriteLine($"Starting package build process for: ({path})");
            string setupFile = DetectPackageType(path);
            Console.WriteLine($"Building package with setup file: {setupFile}");

            string exeDir = AppContext.BaseDirectory;
            string intuneExe = Path.Combine(exeDir, "IntuneWinAppUtil.exe");

            if (!File.Exists(intuneExe))
            {
                Console.WriteLine("Press any key to close...");
                Console.ReadKey();
            }
            // Build logic here
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = intuneExe,
                Arguments = $"-c \"{path}\" -s \"{setupFile}\" -o \"{path}\" -q",
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true,
            };

            string[] animation = new string[] { "-----", "=----", "#=---", "=#=--", "-=#=-", "--=#=", "---=#", "----=" };
            int animationLenght = animation[0].Length;
            Process iwauProcess = new Process();
            iwauProcess.StartInfo = startInfo;
            iwauProcess.Start();

            while (!iwauProcess.HasExited)
            {
                foreach (var frame in animation)
                {
                    Console.Write($"\rBuilding package... ");
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.Write(frame);
                    Console.ResetColor();
                    System.Threading.Thread.Sleep(100);
                }
            }

            Console.Write($"\rBuilding package... ");
            Console.ForegroundColor = ConsoleColor.Green;
            Console.Write("COMPLETED!");
            Console.ResetColor();

            if (iwauProcess.ExitCode != 0)
            {
                Console.WriteLine($"\nError: Packaging process exited with code {iwauProcess.ExitCode}");
                Console.WriteLine("Press any key to close...");
                Console.ReadKey();
            }
            else
            {
                Console.WriteLine($"\nPackage built successfully!");
                Console.WriteLine("Window closes automaticly in 3 seconds...");
                System.Threading.Thread.Sleep(3000);
            }

            iwauProcess.Dispose();
        }

        static void NewPackage(string path)
        {
            string appName = String.Empty;
            string appVersion = String.Empty;
            string appVendor = String.Empty;

            string exeDir = AppContext.BaseDirectory;
            string templateDirectory = Path.Combine(exeDir, "template");
            string templateDirectoryFile = Path.Combine(templateDirectory, "Invoke-AppDeployToolkit.exe");

            if (!File.Exists(templateDirectoryFile))
            {
                Console.WriteLine("Please add a PSADT v4 template to the template directory");
                Console.WriteLine("Press any key to open template directory and close script...");
                Console.ReadKey();
                OpenTemplateDirectory();
                Environment.Exit(0);
            }

            do
            {
                Console.Write("Enter the Application Name: ");
                appName = Console.ReadLine() ?? "";

                if (appName.Length > 0)
                {
                    break;
                }
            } while (true);

            Console.Write("Enter the Application Maker (enter to skip): ");
            appVendor = Console.ReadLine() ?? "";
            Console.Write("Enter the Application Version (enter to skip): ");
            appVersion = Console.ReadLine() ?? "";

            string dirName = $"{appName}";
            if (appVersion.Length > 0)
            {
                dirName = $"{appName} {appVersion}";
            }

            string totalPath = Path.Combine(path, dirName);

            if (Directory.Exists(totalPath))
            {
                Console.WriteLine("That application already exists, change the name and try again...");
                Console.WriteLine("Press any button to close...");
                Console.ReadKey();
                Environment.Exit(0);
            }

            var placeholders = new Dictionary<string, string>
            {
                ["AppName"] = appName,
                ["AppVersion"] = appVersion ?? string.Empty,
                ["AppVendor"] = appVendor ?? string.Empty,
                ["AppScriptDate"] = DateTime.Now.ToString("yyyy/MM/dd"),
                ["AppScriptAuthor"] = Environment.UserName
            };

            CopyDirectory(templateDirectory, totalPath);
            
            ReplacePlaceholdersInFile(Path.Combine(totalPath, "Invoke-AppDeployToolkit.ps1"), placeholders);

            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = "explorer.exe",
                Arguments = totalPath,
                UseShellExecute = true,
            };
            Process.Start(startInfo);
        }

        static void ReplacePlaceholdersInFile(
        string filePath,
        Dictionary<string, string> placeholders)
        {
            if (!File.Exists(filePath))
                throw new FileNotFoundException("Template file not found", filePath);

            Console.WriteLine($"{filePath}");
            if (filePath.Contains("Invoke-AppDeployToolkit"))
            {
                string content = File.ReadAllText(filePath, Encoding.UTF8);

                foreach (var kvp in placeholders)
                {
                    string pattern = $@"^\s*({kvp.Key})\s*=\s*(['""])[^'""]*\2";
                    var regex = new Regex(pattern, RegexOptions.Multiline);

                    content = regex.Replace(content, $"{kvp.Key} = '{kvp.Value}'");
                }

                File.WriteAllText(filePath, content, Encoding.UTF8);

            }
        }

        static void CopyDirectory(string sourceDir, string destDir)
        {
            Directory.CreateDirectory(destDir);

            foreach (string file in Directory.GetFiles(sourceDir))
            {
                string destFile = Path.Combine(destDir, Path.GetFileName(file));
                File.Copy(file, destFile, overwrite: true);
            }

            foreach (string directory in Directory.GetDirectories(sourceDir))
            {
                string destSubDir = Path.Combine(destDir, Path.GetFileName(directory));
                CopyDirectory(directory, destSubDir);
            }
        }


        static void OpenTemplateDirectory()
        {
            string exeDir = AppContext.BaseDirectory;
            string templateDirectory = Path.Combine(exeDir, "template");
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = "explorer.exe",
                Arguments = templateDirectory,
                UseShellExecute = true,
            };
            Process.Start(startInfo);
        }
    }
}