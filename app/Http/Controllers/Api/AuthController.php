<?php
namespace App\Http\Controllers\Api;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use App\Http\Controllers\Controller;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $fields = $request->validate([
            'name' => 'required|string',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|confirmed',
        ]);
        $user = User::create([
            'name' => $fields['name'],
            'email' => $fields['email'],
            'password' => bcrypt($fields['password'])
        ]);
        $token = $user->createToken('myAppToken')->plainTextToken;

        $response = [
            'user' => $user,
            'token' => $token
        ];

        return response($response, 201);
    }


    public function changePassword(Request $request)
    {

        $fields = $request->validate([
            'old_password' => 'required|string',
            'password' => 'required|string|confirmed',
        ]);

        $user = User::find($request->user()->id);

        if (!$user || !Hash::check($fields['old_password'], $user->password)) {
            return response(['message' => 'bad credential'], 401);
        }
        $user->password = bcrypt($fields['password']);
        $updatedUser = $user->save();

        if ($updatedUser == 1) {
            $request->user()->currentAccessToken()->delete();


            return response(['message' => 'Password is changed and you are logged out from all devices'], 201);
        } else {
            return response(['message' => 'not Changed'], 500);

        }
    }

    public function login(Request $request)
    {

        $fields = $request->validate([
            'email' => 'required|string',
            'password' => 'required|string',
        ]);
        $user = User::where('email', $fields['email'])->first();
        if (!$user || !Hash::check($fields['password'], $user->password)) {
            return response(['message' => 'bad credential'], 401);
        }

        $token = $user->createToken('portal')->plainTextToken;

        $response = [
            'user' => $user,
            'token' => $token
        ];

        return response($response, 201);

    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response(['message' => 'logged out'], 201);
    }

}
