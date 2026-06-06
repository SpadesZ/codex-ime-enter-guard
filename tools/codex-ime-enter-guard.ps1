param(
    [ValidateSet('composition', 'plain', 'all')]
    [string]$Mode = 'composition',

    [string]$PidFile = (Join-Path $PSScriptRoot 'codex-ime-enter-guard.pid'),

    [switch]$VerboseGuard,

    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'

$source = @"
using System;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

public static class CodexImeEnterGuard
{
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_SYSKEYDOWN = 0x0104;
    private const int VK_RETURN = 0x0D;
    private const int VK_SHIFT = 0x10;
    private const int VK_CONTROL = 0x11;
    private const int VK_MENU = 0x12;
    private const int GCS_COMPSTR = 0x0008;

    private static LowLevelKeyboardProc proc = HookCallback;
    private static IntPtr hookId = IntPtr.Zero;
    private static string mode = "composition";
    private static bool verbose = false;

    public static void Run(string requestedMode, bool requestedVerbose)
    {
        mode = (requestedMode ?? "composition").ToLowerInvariant();
        verbose = requestedVerbose;
        hookId = SetHook(proc);
        if (hookId == IntPtr.Zero)
        {
            throw new Win32Exception(Marshal.GetLastWin32Error());
        }

        Console.WriteLine("Codex IME Enter Guard running. Mode=" + mode);
        Application.ApplicationExit += delegate { UnhookWindowsHookEx(hookId); };
        Application.Run(new ApplicationContext());
    }

    private static IntPtr SetHook(LowLevelKeyboardProc hookProc)
    {
        using (Process currentProcess = Process.GetCurrentProcess())
        using (ProcessModule currentModule = currentProcess.MainModule)
        {
            return SetWindowsHookEx(
                WH_KEYBOARD_LL,
                hookProc,
                GetModuleHandle(currentModule.ModuleName),
                0);
        }
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0 && (wParam == (IntPtr)WM_KEYDOWN || wParam == (IntPtr)WM_SYSKEYDOWN))
        {
            KBDLLHOOKSTRUCT key = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT));
            if (key.vkCode == VK_RETURN && ShouldBlockEnter())
            {
                if (verbose)
                {
                    Console.WriteLine("Blocked Enter in Codex. Mode=" + mode);
                }
                return (IntPtr)1;
            }
        }

        return CallNextHookEx(hookId, nCode, wParam, lParam);
    }

    private static bool ShouldBlockEnter()
    {
        IntPtr focusedWindow;
        IntPtr foregroundWindow;
        if (!IsCodexForeground(out foregroundWindow, out focusedWindow))
        {
            return false;
        }

        if (mode == "all")
        {
            return true;
        }

        if (mode == "plain")
        {
            return !IsKeyDown(VK_SHIFT) && !IsKeyDown(VK_CONTROL) && !IsKeyDown(VK_MENU);
        }

        return HasImeComposition(focusedWindow) || HasImeComposition(foregroundWindow);
    }

    private static bool IsCodexForeground(out IntPtr foregroundWindow, out IntPtr focusedWindow)
    {
        foregroundWindow = GetForegroundWindow();
        focusedWindow = GetFocusedWindow(foregroundWindow);
        if (foregroundWindow == IntPtr.Zero)
        {
            return false;
        }

        uint processId;
        GetWindowThreadProcessId(foregroundWindow, out processId);
        try
        {
            Process process = Process.GetProcessById((int)processId);
            if (process.ProcessName.IndexOf("codex", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                return true;
            }
        }
        catch
        {
        }

        string title = GetWindowTextManaged(foregroundWindow);
        return title.IndexOf("Codex", StringComparison.OrdinalIgnoreCase) >= 0;
    }

    private static IntPtr GetFocusedWindow(IntPtr foregroundWindow)
    {
        if (foregroundWindow == IntPtr.Zero)
        {
            return IntPtr.Zero;
        }

        uint focusedProcessId;
        uint foregroundThread = GetWindowThreadProcessId(foregroundWindow, out focusedProcessId);
        uint currentThread = GetCurrentThreadId();
        bool attached = false;
        if (foregroundThread != 0 && foregroundThread != currentThread)
        {
            attached = AttachThreadInput(currentThread, foregroundThread, true);
        }

        try
        {
            IntPtr focusedWindow = GetFocus();
            return focusedWindow == IntPtr.Zero ? foregroundWindow : focusedWindow;
        }
        finally
        {
            if (attached)
            {
                AttachThreadInput(currentThread, foregroundThread, false);
            }
        }
    }

    private static bool HasImeComposition(IntPtr window)
    {
        if (window == IntPtr.Zero)
        {
            return false;
        }

        IntPtr inputContext = ImmGetContext(window);
        if (inputContext == IntPtr.Zero)
        {
            return false;
        }

        try
        {
            int compositionBytes = ImmGetCompositionStringW(inputContext, GCS_COMPSTR, IntPtr.Zero, 0);
            return compositionBytes > 0;
        }
        finally
        {
            ImmReleaseContext(window, inputContext);
        }
    }

    private static bool IsKeyDown(int virtualKey)
    {
        return (GetKeyState(virtualKey) & 0x8000) != 0;
    }

    private static string GetWindowTextManaged(IntPtr window)
    {
        StringBuilder buffer = new StringBuilder(512);
        GetWindowText(window, buffer, buffer.Capacity);
        return buffer.ToString();
    }

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    private struct KBDLLHOOKSTRUCT
    {
        public uint vkCode;
        public uint scanCode;
        public uint flags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll")]
    private static extern IntPtr GetFocus();

    [DllImport("user32.dll")]
    private static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

    [DllImport("kernel32.dll")]
    private static extern uint GetCurrentThreadId();

    [DllImport("user32.dll")]
    private static extern short GetKeyState(int nVirtKey);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("imm32.dll")]
    private static extern IntPtr ImmGetContext(IntPtr hWnd);

    [DllImport("imm32.dll")]
    private static extern bool ImmReleaseContext(IntPtr hWnd, IntPtr hIMC);

    [DllImport("imm32.dll", CharSet = CharSet.Unicode)]
    private static extern int ImmGetCompositionStringW(IntPtr hIMC, int dwIndex, IntPtr lpBuf, int dwBufLen);
}
"@

Add-Type -TypeDefinition $source -ReferencedAssemblies @('System.Windows.Forms.dll')

if ($SelfTest) {
    Write-Host 'Codex IME Enter Guard self-test OK.'
    return
}

Set-Content -LiteralPath $PidFile -Value $PID -Encoding ASCII
try {
    [CodexImeEnterGuard]::Run($Mode, [bool]$VerboseGuard)
}
finally {
    if (Test-Path -LiteralPath $PidFile) {
        Remove-Item -LiteralPath $PidFile -Force
    }
}
