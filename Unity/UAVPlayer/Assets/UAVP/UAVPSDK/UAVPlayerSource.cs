﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;

public class UAVPlayerSource: UAVPFoundation
{
#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
#endif
    private static extern bool UAVP_CanOutputToTexture(string videoPath);

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
#endif
    private static extern bool UAVP_PlayerReady();

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
#endif
    private static extern float UAVP_DurationSeconds();

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
#endif
    private static extern float UAVP_CurrentSeconds();

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
#endif
    private static extern void UAVP_VideoExtents(ref int w, ref int h);

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
#endif
    private static extern System.IntPtr UAVP_CurFrameTexture();

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
#endif
    private static extern UAVPError UAVP_InitPlayer();

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
#endif
    private static extern UAVPError UAVP_OpenVideo(string videoPath);

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
#endif
    private static extern UAVPError UAVP_PlayVideo();

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
#endif
    private static extern void UAVP_PauseVideo();

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
#endif
    private static extern void UAVP_ResumeVideo();

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
#endif
    private static extern void UAVP_ReleasePlayer();
    
     public UAVPlayerSource()
    {
        Debug.Log("[UAVPlayer_Souce] Init");
    }

    // Check whether the Media is playing or not
    public bool videoReady
    {
        get
        {
            return UAVP_PlayerReady();
        }
    }

    // Return the whole playable time of the media(unit: seconds(s))
    public float videoDuration
    {
        get
        {
            return UAVP_DurationSeconds();
        }
    }

    // Return currently being played(unit: seconds(s))
    public float videoCurremtTime
    {
        get
        {
            return UAVP_CurrentSeconds();
        }
    }

    // Return the media texture width
    public int videoWidth
    {
        get
        {
            int w = 0, h = 0;
            UAVP_VideoExtents(ref w, ref h);
            return w;
        }
    }

    // Return the media texture height
    public int videoHeight
    {
        get
        {
            int w = 0, h = 0;
            UAVP_VideoExtents(ref w, ref h);
            return h;
        }
    }

    public bool mute;                       // Set whether to turn off the audio or not
    public bool loop;                       // Set the when the video reaches the end poosition it jumps to the start position and plays again
    public bool autoPlayback;               // Set the playing video automatically when app is started
    public UAVPLogLevel logLevelForDebugging;   // Set Log level for debugging
    // Set the audio volume
    private float _volume = 1.0f;
    public float volume
    {
        get
        {
            return _volume;
        }
        set
        {
            if(_volume > 100.0f)
            {
                _volume = 1.0f;
            }
            else if(_volume < 0.0f)
            {
                _volume = 0.0f;
            }
            else
            {
                _volume = value / 100.0f;
            }
        }
    }

    // Initialize the Media Player
    public override UAVPError InitPlayer(UAVPLogLevel logLevel)
    {
        UAVPError error = UAVP_InitPlayer();

        return error;
    }

    // Open the Media
    public override UAVPError OpenMedia(string URI, UAVPMediaType mediaType)
    {
        Debug.Log("[UAVPlayer_Play] URL[" + URI + "]");
        UAVPError error = UAVPError.UAVP_ERROR_NONE;

        if (CanOutputToTexture(URI))
        {
            error = UAVP_OpenVideo(URI);
        }
        else
        {
            error = UAVPError.UAVP_Error_OPENFAILED;
        }
        return error;
    }

    // Start to media playback
    public override void Start()
    {
        Debug.Log("[UAVPlayer_Start]");
        UAVP_PlayVideo();
    }

    // Pause the Player
    public override void Pause()
    {
        Debug.Log("[UAVPlayer_Pause]");
        if(videoReady)
        {
            UAVP_PauseVideo();
        }
    }

    // Resume the Player
    public override void Resume()
    {
        Debug.Log("[UAVPlayer_Resume]");
        UAVP_ResumeVideo();
    }

    // Release the Player
    public override void Release()
    {
        Debug.Log("[UAVPlayer_Release]");
        UAVP_ReleasePlayer();
    }

    // Video Texture
    private Texture2D _videoTexture = null;
    public Texture2D videoTexture
    {
        get
        {
            System.IntPtr nativeTex = videoReady ? UAVP_CurFrameTexture() : System.IntPtr.Zero;
            if(nativeTex != System.IntPtr.Zero)
            {
                if(_videoTexture == null && videoWidth != 0 && videoHeight != 0)
                {
                    Debug.Log("[UAVPlayer] Create Texture width: " + videoWidth + ", height: " + videoHeight);
                    _videoTexture = Texture2D.CreateExternalTexture(videoWidth, videoHeight, TextureFormat.BGRA32, false, false, nativeTex);
                    _videoTexture.filterMode = FilterMode.Bilinear;
                    _videoTexture.wrapMode = TextureWrapMode.Repeat;
                }

                Debug.Log("[UAVPlayer] try update Texture");
                _videoTexture.UpdateExternalTexture(nativeTex);
            }
            else
            {
                Debug.Log("[UAVPlayer] native texture is zero");
                _videoTexture = null;
            }

            return _videoTexture;
        }
    }

    // Check the whether player can play media or not
    public static bool CanOutputToTexture(string videoPath)
    {
        bool canOutputTexture = UAVP_CanOutputToTexture(videoPath);
        if(canOutputTexture)
        {
            Debug.Log("[UAVPlayer] Player can play the media");
        }
        else
        {
            Debug.Log("[UAVPlayer] Player cannot play the media");
        }
        return canOutputTexture;
    }
}
