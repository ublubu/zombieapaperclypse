{-# LANGUAGE PackageImports #-}

----
-- The comments borrow liberally from Anton Gerdelan's OpenGL book.
--     https://github.com/capnramses/antons_opengl_tutorials_book
----

import qualified Graphics.Rendering.OpenGL as GL
import Graphics.Rendering.OpenGL (($=))
import qualified "GLFW-b" Graphics.UI.GLFW as GLFW
import Control.Monad
import System.Exit (exitWith, ExitCode(..))
import qualified LoadShaders as Shaders
import qualified Foreign.Marshal.Array as Arr
import qualified Foreign.Ptr as Ptr
import qualified Foreign.Storable as Stor

data VaoDescriptor = VaoDescriptor GL.VertexArrayObject GL.ArrayIndex GL.NumArrayIndices
bufferOffset :: Integral a => a -> Ptr.Ptr b
bufferOffset = Ptr.plusPtr Ptr.nullPtr . fromIntegral

initResources :: IO VaoDescriptor
initResources = do

    let vertices = [
            GL.Vertex2 (-0.90) (-0.90), -- first triangle
            GL.Vertex2 0.85 (-0.90),
            GL.Vertex2 (-0.90) 0.85,
            GL.Vertex2 0.90 (-0.85), -- second triangle
            GL.Vertex2 0.90 0.90,
            GL.Vertex2 (-0.85) 0.90 ] :: [GL.Vertex2 GL.GLfloat]
        numVertices = length vertices

    ----
    -- Bind an array buffer (vertex buffer object) and copy the vertices into it.
    --     This stores an array of data in graphics memory.
    ----

    arrayBuffer <- GL.genObjectName -- glGenBuffers (1, &vbo)
    GL.bindBuffer GL.ArrayBuffer $= Just arrayBuffer -- glBindBuffer(GL_ARRAY_BUFFER, vbo)

    -- glBufferData (GL_ARRAY_BUFFER, 9 * sizeof (GLfloat), points, GL_STATIC_DRAW)
    Arr.withArray vertices $ \ptr -> do
        let size = fromIntegral (numVertices * Stor.sizeOf (head vertices))
        GL.bufferData GL.ArrayBuffer $= (size, ptr, GL.StaticDraw)

    ----
    -- Bind a vertex array object (VAO) and tell it to use the VBO and say
    --     'every three floats is a variable'
    --
    -- The VAO is a little descriptor that defines which data from VBOs should be
    --     used as input variables to vertex shaders.
    ----

    triangles <- GL.genObjectName -- glGenVertexArrays (1, &vao)
    GL.bindVertexArrayObject $= Just triangles -- glBindVertexArray (vao)

    let firstIndex = 0
        vPosition = GL.AttribLocation 0
    --   void glVertexAttribPointer(  GLuint index,
    --        GLint size,
    --        GLenum type,
    --        GLboolean normalized,
    --        GLsizei stride,
    --        const GLvoid * pointer);
    --
    -- glVertexAttribPointer (0, 2, GL_FLOAT, GL_FALSE, 0, NULL)
    --
    -- VertexArrayDescriptor !NumComponents !DataType !Stride !(Ptr a)
    GL.vertexAttribPointer vPosition $=
        (GL.ToFloat, GL.VertexArrayDescriptor 2 GL.Float 0 (bufferOffset firstIndex))
    GL.vertexAttribArray vPosition $= GL.Enabled -- glEnableVertexAttribArray (0)

    ----
    -- Load shader program
    ----

    program <- Shaders.loadShaders [
        Shaders.ShaderInfo GL.VertexShader (Shaders.FileSource "blu.vert"),
        Shaders.ShaderInfo GL.FragmentShader (Shaders.FileSource "blu.frag")]
    GL.currentProgram $= Just program

    return $ VaoDescriptor triangles firstIndex (fromIntegral numVertices)

main :: IO ()
main = do
    GLFW.init
    GLFW.defaultWindowHints
    GLFW.windowHint $ GLFW.WindowHint'ContextVersionMajor 4
    GLFW.windowHint $ GLFW.WindowHint'ContextVersionMinor 1
    GLFW.windowHint $ GLFW.WindowHint'OpenGLForwardCompat True
    GLFW.windowHint $ GLFW.WindowHint'OpenGLProfile GLFW.OpenGLProfile'Core
    Just win <- GLFW.createWindow 640 480 "GLFW Demo" Nothing Nothing
    GLFW.makeContextCurrent (Just win)
    descriptor <- initResources
    onDisplay win descriptor
    GLFW.destroyWindow win
    GLFW.terminate

onDisplay :: GLFW.Window -> VaoDescriptor -> IO ()
onDisplay win descriptor@(VaoDescriptor triangles firstIndex numVertices) = do
    GL.clearColor $= GL.Color4 1 0 0 1
    GL.clear [GL.ColorBuffer]
    GL.bindVertexArrayObject $= Just triangles
    GL.drawArrays GL.Triangles firstIndex numVertices
    GLFW.swapBuffers win
    onDisplay win descriptor
