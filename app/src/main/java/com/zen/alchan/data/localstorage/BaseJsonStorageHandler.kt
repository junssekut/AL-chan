package com.zen.alchan.data.localstorage

import android.content.Context
import com.google.gson.reflect.TypeToken
import io.sentry.Sentry
import java.io.*
import java.lang.reflect.Type

abstract class BaseJsonStorageHandler(
    private val context: Context
) {

    protected inline fun <reified T> getType(): Type {
        return object : TypeToken<T>(){}.type
    }

    private val externalFileDir by lazy {
        context.getExternalFilesDir(null)
    }

    protected fun setData(fileName: String, value: String) {
        var outputStream: FileOutputStream? = null

        try {
            val targetFolder = File(externalFileDir?.path)

            if (!targetFolder.exists()) {
                targetFolder.mkdir()
            }

            val targetFile = File(externalFileDir, fileName)

            if (targetFile.exists()) {
                targetFile.delete()
                targetFile.createNewFile()
            }

            outputStream = FileOutputStream(targetFile, false)
            outputStream.write(value.toByteArray())
        } catch (e: Exception) {
            Sentry.captureException(e)
            e.printStackTrace()
        } finally {
            outputStream?.flush()
            outputStream?.close()
        }
    }

    protected fun getData(fileName: String): String? {
        var inputStream: InputStream? = null

        try {
            val targetFile = File(externalFileDir, fileName)

            inputStream = FileInputStream(targetFile)
            val inputStreamReader = InputStreamReader(inputStream)
            val bufferedReader = BufferedReader(inputStreamReader)

            val stringBuilder = StringBuilder()
            bufferedReader.readLines().forEach {
                stringBuilder.append(it)
            }
            inputStream.close()
            return stringBuilder.toString()
        } catch (e: Exception) {
            Sentry.captureException(e)
            inputStream?.close()
            return null
        }   return null
        }
    }
}