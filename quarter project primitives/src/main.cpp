/*
ZJ Wood CPE 471 Lab 3 base code
*/

#include <iostream>
#include <string>
#include <glad/glad.h>

#include "GLSL.h"
#include "Program.h"
#include "WindowManager.h"

// value_ptr for glm
#include <glm/gtc/type_ptr.hpp>
#include <glm/gtc/matrix_transform.hpp>
bool p1f, p1b, p1l, p1r, bu, bd;
float p1x = 0.0, p1y = 0.0;
float blending = 0.0;
int scene = 1;
int noise = 0;
float movementSpeed = 0.005;
GLfloat g_vertex_buffer_data[] =
        {
                -1.0f, -1.0f, 0.0f,
                -1.0f, 1.0f, 0.0f,
                1.0f, 1.0f, 0.0f,

                1.0f, 1.0f, 0.0f,
                1.0f, -1.0f, 0.0f,
                -1.0f, -1.0f, 0.0f
        };
float timeTotal;
float timeDelta;
int iterator;
//glm::vec3 pos;

double posX, posY;
int width, height;

double get_last_elapsed_time()
{
    static double lasttime = glfwGetTime();
    double actualtime =glfwGetTime();
    double difference = actualtime- lasttime;
    lasttime = actualtime;
    return difference;
}
class camera
{
public:
    glm::vec3 pos, rot;
    int w, a, s, d;
    int up, down, left, right;
    camera()
    {
        w = a = s = d = 0;
        pos = rot = glm::vec3(0, 0, 0);
    }
    glm::mat4 process(double ftime)
    {
        float speed = 0;
        if (w == 1)
        {
            speed = 4*ftime;
        }
        else if (s == 1)
        {
            speed = -4*ftime;
        }
        float yangle=0;

        float xangle=0;
        yangle = ((posX/width)  -(0.5)) * 10 * ftime;
        xangle = ((posY/height) -(0.5)) * 10 * ftime;
        if (a == 1)
            yangle = -3*ftime;
        else if(d==1)
            yangle = 3*ftime;
        rot.y += yangle;
        rot.x += xangle;
        glm::mat4 R = glm::rotate(glm::mat4(1), rot.x, glm::vec3(1, 0, 0));
        R *= glm::rotate(glm::mat4(1), rot.y, glm::vec3(0, 1, 0));

        glm::vec4 dir = glm::vec4(0, 0, speed,1);
        //dir = dir*glm::rotate(glm::mat4(1), rot.y, glm::vec3(0, 1, 0));;
        dir = dir * R;
        pos += glm::vec3(dir.x, dir.y, dir.z);
        glm::mat4 T = glm::translate(glm::mat4(1), pos);
        return R*T;
    }
};

camera mycam;


class Application : public EventCallbacks
{

public:

	WindowManager * windowManager = nullptr;

	// Our shader program
	std::shared_ptr<Program> prog;

	// Contains vertex information for OpenGL
	GLuint VertexArrayID;

	// Data necessary to give our triangle to OpenGL
	GLuint VertexBufferID;

	void keyCallback(GLFWwindow *window, int key, int scancode, int action, int mods)
	{
		if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
		{
			glfwSetWindowShouldClose(window, GL_TRUE);
		}
        if (key == GLFW_KEY_W && action == GLFW_PRESS)
        {
            p1f = 1;
        }
        if (key == GLFW_KEY_W && action == GLFW_RELEASE)
        {
            p1f = 0;
        }
        if (key == GLFW_KEY_S && action == GLFW_PRESS)
        {
            p1b = 1;
        }
        if (key == GLFW_KEY_S && action == GLFW_RELEASE)
        {
            p1b = 0;
        }
        if (key == GLFW_KEY_A && action == GLFW_PRESS)
        {
            p1l = 1;
        }
        if (key == GLFW_KEY_A && action == GLFW_RELEASE)
        {
            p1l = 0;
        }
        if (key == GLFW_KEY_D && action == GLFW_PRESS)
        {
            p1r = 1;
        }
        if (key == GLFW_KEY_D && action == GLFW_RELEASE)
        {
            p1r = 0;
        }


        if (key == GLFW_KEY_R && action == GLFW_PRESS) {
            bu = true;
        }
        if (key == GLFW_KEY_R && action == GLFW_RELEASE) {
            bu = false;
        }
        if (key == GLFW_KEY_F && action == GLFW_PRESS) {
            bd = true;
        }
        if (key == GLFW_KEY_F && action == GLFW_RELEASE) {
            bd = false;
        }

        if (key == GLFW_KEY_1 && action == GLFW_PRESS) {
            scene = 1;
        }
        if (key == GLFW_KEY_2 && action == GLFW_PRESS) {
            scene = 2;
        }
        if (key == GLFW_KEY_3 && action == GLFW_PRESS) {
            scene = 3;
        }
        if (key == GLFW_KEY_4 && action == GLFW_PRESS) {
            noise = 0;
        }
        if (key == GLFW_KEY_5 && action == GLFW_PRESS) {
            noise = 1;
        }



	}

	// callback for the mouse when clicked move the triangle when helper functions
	// written
	void mouseCallback(GLFWwindow *window, int button, int action, int mods)
	{
		double posX, posY;
		float newPt[2];
		if (action == GLFW_PRESS)
		{
			glfwGetCursorPos(window, &posX, &posY);
			std::cout << "Pos X " << posX <<  " Pos Y " << posY << std::endl;
//
//			//change this to be the points converted to WORLD
//			//THIS IS BROKEN< YOU GET TO FIX IT - yay!
//			newPt[0] = 0;
//			newPt[1] = 0;
//
//			std::cout << "converted:" << newPt[0] << " " << newPt[1] << std::endl;
//			glBindBuffer(GL_ARRAY_BUFFER, VertexBufferID);
//			//update the vertex array with the updated points
//			glBufferSubData(GL_ARRAY_BUFFER, sizeof(float)*6, sizeof(float)*2, newPt);
//			glBindBuffer(GL_ARRAY_BUFFER, 0);
		}
	}

	//if the window is resized, capture the new size and reset the viewport
	void resizeCallback(GLFWwindow *window, int in_width, int in_height)
	{
		//get the window size - may be different then pixels for retina
		int width, height;
		glfwGetFramebufferSize(window, &width, &height);
		glViewport(0, 0, width, height);
	}

	/*Note that any gl calls must always happen after a GL state is initialized */
	void initGeom()
	{
		//generate the VAO
		glGenVertexArrays(1, &VertexArrayID);
		glBindVertexArray(VertexArrayID);

		//generate vertex buffer to hand off to OGL
		glGenBuffers(1, &VertexBufferID);
		//set the current state to focus on our vertex buffer
		glBindBuffer(GL_ARRAY_BUFFER, VertexBufferID);


		//actually memcopy the data - only do this once
		glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_DYNAMIC_DRAW);

		//we need to set up the vertex array
		glEnableVertexAttribArray(0);
		//key function to get up how many elements to pull out at a time (3)
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, (void*) 0);

		glBindVertexArray(0);

	}

	//General OGL initialization - set OGL state here
	void init(const std::string& resourceDirectory)
	{
		GLSL::checkVersion();

		// Set background color.
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		// Enable z-buffer test.
		glEnable(GL_DEPTH_TEST);

		// Initialize the GLSL program.
		prog = std::make_shared<Program>();
		prog->setVerbose(true);
		prog->setShaderNames(resourceDirectory + "/shader_vertex.glsl", resourceDirectory + "/shader_fragment.glsl");
		prog->init();
		prog->addUniform("P");
		prog->addUniform("V");
		prog->addUniform("M");
        prog->addUniform("camera");
        prog->addUniform("u_time");
        prog->addUniform("S1");
        prog->addUniform("BF");
        prog->addUniform("Scene");
        prog->addUniform("Noise");
        prog->addUniform("camPos");
        prog->addUniform("camRot");
        prog->addUniform("u_resolution");
		prog->addAttribute("vertPos");
	}


	/****DRAW
	This is the most important function in your program - this is where you
	will actually issue the commands to draw any geometry you have set up to
	draw
	********/
	void render()
	{
        double frametime = get_last_elapsed_time();
        mycam.process(frametime);
        glfwGetCursorPos(windowManager->getHandle(), &posX, &posY);

        iterator ++;
        if(iterator > 10) {
            timeDelta = glfwGetTime() - timeTotal;
            timeTotal = glfwGetTime();
            printf("FPS: %f\n", 10 / timeDelta);
            iterator = 0;
        }

		glfwGetFramebufferSize(windowManager->getHandle(), &width, &height);
		float aspect = width/(float)height;
		glViewport(0, 0, width, height);


        if(p1l)
            p1x -=movementSpeed * timeDelta*50;
        if(p1r)
            p1x +=movementSpeed * timeDelta*50;

        if(p1f)
            p1y +=movementSpeed * timeDelta*50;
        if(p1b)
            p1y -=movementSpeed * timeDelta*50;

        if(bu)
            blending += .002f * timeDelta*100;
        if(bd)
            blending -= .002f * timeDelta*100;

        glBindBuffer(GL_ARRAY_BUFFER, VertexBufferID);
        g_vertex_buffer_data[0] = -1.0f* aspect;
        g_vertex_buffer_data[3] = -1.0f* aspect;
        g_vertex_buffer_data[6] =  1.0f* aspect;
        g_vertex_buffer_data[9] =  1.0f* aspect;
        g_vertex_buffer_data[12] =  1.0f* aspect;
        g_vertex_buffer_data[15] = -1.0f* aspect;
        glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_DYNAMIC_DRAW);
		// Clear framebuffer.
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		// Create the matrix stacks - please leave these alone for now
		
		glm::mat4 V, M, PP;
		V = glm::mat4(1);
		M = glm::mat4(1);
		// Apply orthographic projection.
		PP = glm::ortho(-1 * aspect, 1 * aspect, -1.0f, 1.0f, -2.0f, 100.0f);		
		if (width < height)
		{
		PP = glm::ortho(-1.0f, 1.0f, -1.0f / aspect,  1.0f / aspect, -2.0f, 100.0f);
		}
	
		// Draw the triangle using GLSL.
		prog->bind();
        glm::mat4 cam = glm::mat4(1.0);
        //glm::mat4 cam = glm::translate(glm::mat4(1), glm::vec3(0.5+(sin(glfwGetTime())/2.0), 0.0f, 0.0f));
		//send the matrices to the shaders
		glUniformMatrix4fv(prog->getUniform("P"), 1, GL_FALSE, &PP[0][0]);
		glUniformMatrix4fv(prog->getUniform("V"), 1, GL_FALSE, &V[0][0]);
		glUniformMatrix4fv(prog->getUniform("M"), 1, GL_FALSE, &M[0][0]);
        glUniformMatrix4fv(prog->getUniform("camera"), 1, GL_FALSE, &cam[0][0]);
        glUniform2f(prog->getUniform("u_resolution"), (float)width, (float)height);
        glUniform1f(prog->getUniform("u_time"),(float)glfwGetTime());
        glUniform2f(prog->getUniform("S1"), p1x, p1y);
        glUniform1f(prog->getUniform("BF"), blending);
        glUniform1i(prog->getUniform("Scene"), scene);
        glUniform1i(prog->getUniform("Noise"), noise);
        glUniform3f(prog->getUniform("camPos"), mycam.pos.x, mycam.pos.y, mycam.pos.z);
        glUniform3f(prog->getUniform("camRot"), mycam.rot.x, mycam.rot.y, mycam.rot.z);
        //glUniform2f(prog->getUniform("S2"), 1.0f, 1.0f);
		glBindVertexArray(VertexArrayID);

		//actually draw from vertex 0, 3 vertices
		glDrawArrays(GL_TRIANGLES, 0, 6);

		glBindVertexArray(0);

		prog->unbind();

	}

};
//******************************************************************************************
int main(int argc, char **argv)
{
	std::string resourceDir = "../resources"; // Where the resources are loaded from
	if (argc >= 2)
	{
		resourceDir = argv[1];
	}

	Application *application = new Application();

	/* your main will always include a similar set up to establish your window
		and GL context, etc. */
	WindowManager * windowManager = new WindowManager();
	windowManager->init(640, 480);
	windowManager->setEventCallbacks(application);
	application->windowManager = windowManager;

	/* This is the code that will likely change program to program as you
		may need to initialize or set up different data and state */
	// Initialize scene.
	application->init(resourceDir);
	application->initGeom();

	// Loop until the user closes the window.
	while(! glfwWindowShouldClose(windowManager->getHandle()))
	{
		// Render scene.
		application->render();

		// Swap front and back buffers.
		glfwSwapBuffers(windowManager->getHandle());
		// Poll for and process events.
		glfwPollEvents();
	}

	// Quit program.
	windowManager->shutdown();
	return 0;
}
